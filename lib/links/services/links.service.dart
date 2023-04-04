import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../doc-tree/const/link-prefixes.const.dart';
import '../../document/models/attributes/attributes.model.dart';
import '../../document/models/nodes/node.model.dart';
import '../../document/services/nodes/node.utils.dart';
import '../../selection/services/selection.service.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/utils/platform.utils.dart';
import '../../styles/services/styles.service.dart';
import '../models/link-action-menu.enum.dart';
import '../models/link-action.picker.type.dart';

// Links can either be opened or copied.
class LinksService {
  late final StylesService _stylesService;
  late final SelectionService _selectionService;

  final _nodeUtils = NodeUtils();

  final EditorState state;

  LinksService(this.state) {
    _stylesService = StylesService(state);
    _selectionService = SelectionService(state);
  }

  bool canLaunchLinks(bool metaOrControlPressed) {
    // In readOnly mode users can launch links  by simply tapping (clicking) on them
    if (state.config.readOnly) return true;

    // In editing mode it depends on the platform:
    // Desktop platforms (macos, linux, windows):
    // only allow Meta(Control) + Click combinations
    if (isDesktop()) {
      return metaOrControlPressed;
    }
    // Mobile platforms (ios, android): always allow but we install a  long-press handler instead of a tap one.
    // LongPress is followed by a context menu with actions.
    return true;
  }

  // Cache gesture recognizers so we can cancel them later.
  GestureRecognizer getRecognizer(
    NodeM node,
    LinkActionPicker linkActionPicker,
    Map<NodeM, GestureRecognizer> linkRecognizers,
  ) {
    if (linkRecognizers.containsKey(node)) {
      return linkRecognizers[node]!;
    }

    if (isDesktop() || state.config.readOnly) {
      linkRecognizers[node] = TapGestureRecognizer()
        ..onTap = () => _tapNodeLink(node);
    } else {
      linkRecognizers[node] = LongPressGestureRecognizer()
        ..onLongPress = () => _longPressLink(node, linkActionPicker);
    }

    return linkRecognizers[node]!;
  }

  // When the author attempt to edit a link we need to edit the entire link
  // length regardless of how much from the link was selected.
  // The link range is extracted by analysing which neighbouring nodes contain the same link attribute.
  // Once we know the range of a link we can then apply the changes on the entire link, not only on the selected part.
  TextRange getLinkRange(NodeM node) {
    var start = _nodeUtils.getDocumentOffset(node);
    var length = node.charsNum;
    var prev = node.previous;
    final linkAttr = node.style.attributes[AttributesM.link.key]!;

    while (prev != null) {
      if (prev.style.attributes[AttributesM.link.key] == linkAttr) {
        start = _nodeUtils.getDocumentOffset(prev);
        length += prev.charsNum;
        prev = prev.previous;
      } else {
        break;
      }
    }

    var next = node.next;

    while (next != null) {
      if (next.style.attributes[AttributesM.link.key] == linkAttr) {
        length += next.charsNum;
        next = next.next;
      } else {
        break;
      }
    }

    return TextRange(
      start: start,
      end: start + length,
    );
  }

  // Links can be removed either from link menu or users also have the free choice
  // the decide when to remove them from the outside of the editor.
  void removeSelectionLink() {
    var index = _selectionService.selection.start;
    var length = _selectionService.selection.end - index;

    // Checks if selection has link attr and a valid url or not.
    if (_getLinkAttributeValue() != null) {
      final leaf = state.refs.documentController.queryNode(index).leaf;

      if (leaf != null) {
        final range = getLinkRange(leaf);

        index = range.start;
        length = range.end - range.start;
      }
    }

    // Stores the text that is set as a link, it can either be a alias which contains a link
    // or a URL directly pointing.
    final linkText = state.refs.documentController.getPlainTextAtRange(
      index,
      length,
    );

    // Replaces link with the same text value but without the link attribute.
    state.refs.controller.replaceText(
      index,
      length,
      linkText,
      null,
    );
  }

  // The location at which the link menu should be placed on the screen.
  // It should be placed with the tooltip pointing below the first letter of a link.
  Offset getOffsetForLinkMenu() {
    final linkRect = state.selectedLink.selectedLinkRectangles;

    if (linkRect != null && linkRect.isNotEmpty) {
      final firstLinkRectIsNotEmpty = linkRect[0].rectangles.isNotEmpty;

      if (firstLinkRectIsNotEmpty) {
        final isLinkSelected =
        _stylesService.getSelectionStyle().attributes.containsKey('link');

        if (isLinkSelected) {
          // Get positions for offset
          final rectangle = linkRect[0].rectangles[0];
          final lineOffset = linkRect[0].docRelPosition;

          // In order to place the tooltip menu with the arrow starting tipping at the
          // first char in a link, we need to keep in mind the margin position.
          const triangleTooltipMargin = 15;

          // Editor topbar
          const topBarHeight = 50;

          final scrollOffset = state.refs.scrollController.offset;

          final heightOffset = Offset(
            0,
            lineOffset.dy + rectangle.bottom - scrollOffset + topBarHeight,
          );

          // Width must be converted to global in order to place the menu at the correct coordinates
          // using the Overlay in flutter.
          final widthOffset = Offset(rectangle.left, 0);
          final widthToGlobalOffset =
          state.refs.renderer.localToGlobal(widthOffset);

          return Offset(
            widthToGlobalOffset.dx - triangleTooltipMargin,
            heightOffset.dy,
          );
        }
      }
    }

    // Fail case
    return Offset.infinite;
  }

  // === PRIVATE ===

  String? _getLinkAttributeValue() => _stylesService
      .getSelectionStyle()
      .attributes[AttributesM.link.key]
      ?.value;

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  void _tapNodeLink(NodeM node) {
    final link = node.style.attributes[AttributesM.link.key]!.value;

    _tapLink(link);
  }

  void _tapLink(String? link) {
    if (link == null) {
      return;
    }

    var launchUrl = state.config.onLaunchUrl;
    launchUrl ??= _launchUrl;

    link = link.trim();

    if (!linkPrefixes.any(
      (linkPrefix) => link!.toLowerCase().startsWith(linkPrefix),
    )) {
      link = 'https://$link';
    }

    launchUrl(link);
  }

  Future<void> _longPressLink(
    NodeM node,
    LinkActionPicker linkActionPicker,
  ) async {
    final link = node.style.attributes[AttributesM.link.key]!.value!;
    final action = await linkActionPicker(node);

    switch (action) {
      case LinkMenuAction.launch:
        _tapLink(link);
        break;

      case LinkMenuAction.copy:
        // ignore: unawaited_futures
        Clipboard.setData(
          ClipboardData(text: link),
        );
        break;

      case LinkMenuAction.remove:
        final range = getLinkRange(node);
        _stylesService.formatTextRange(
          range.start,
          range.end - range.start,
          AttributesM.link,
        );
        break;

      case LinkMenuAction.none:
        break;
    }
  }
}
