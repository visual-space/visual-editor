import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../doc-tree/const/link-prefixes.const.dart';
import '../../document/models/attributes/attributes.model.dart';
import '../../document/models/nodes/node.model.dart';
import '../../document/services/nodes/node.utils.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/utils/platform.utils.dart';
import '../../styles/services/styles.service.dart';
import '../models/link-action-menu.enum.dart';
import '../models/link-action.picker.type.dart';

// Links can either be opened or copied.
class LinksService {
  late final StylesService _stylesService;
  final _nodeUtils = NodeUtils();

  final EditorState state;

  LinksService(this.state) {
    _stylesService = StylesService(state);
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

    return TextRange(start: start, end: start + length);
  }

  // === PRIVATE ===

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
        _stylesService.formatSelectedText(
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
