import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../documents/models/attributes/attributes.model.dart';
import '../../documents/models/nodes/node.model.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/utils/platform.utils.dart';
import '../const/link-prefixes.const.dart';
import '../models/link-action-menu.enum.dart';
import '../models/link-action.picker.type.dart';
import '../services/link.utils.dart';

// Links can either be opened or copied.
class TextLineLinkUtils {
  bool canLaunchLinks(EditorState state, bool metaOrControlPressed) {
    // In readOnly mode users can launch links  by simply tapping (clicking) on them
    if (state.editorConfig.config.readOnly) return true;

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
    EditorState state,
    LinkActionPicker linkActionPicker,
    Map<NodeM, GestureRecognizer> linkRecognizers,
  ) {
    if (linkRecognizers.containsKey(node)) {
      return linkRecognizers[node]!;
    }

    if (isDesktop() || state.editorConfig.config.readOnly) {
      linkRecognizers[node] = TapGestureRecognizer()
        ..onTap = () => _tapNodeLink(node, state);
    } else {
      linkRecognizers[node] = LongPressGestureRecognizer()
        ..onLongPress = () => _longPressLink(node, state, linkActionPicker);
    }

    return linkRecognizers[node]!;
  }

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  void _tapNodeLink(NodeM node, EditorState state) {
    final link = node.style.attributes[AttributesM.link.key]!.value;

    _tapLink(link, state);
  }

  void _tapLink(String? link, EditorState state) {
    if (link == null) {
      return;
    }

    var launchUrl = state.editorConfig.config.onLaunchUrl;
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
    EditorState state,
    LinkActionPicker linkActionPicker,
  ) async {
    final link = node.style.attributes[AttributesM.link.key]!.value!;
    final action = await linkActionPicker(node, state);

    switch (action) {
      case LinkMenuAction.launch:
        _tapLink(link, state);
        break;

      case LinkMenuAction.copy:
        // ignore: unawaited_futures
        Clipboard.setData(
          ClipboardData(text: link),
        );
        break;

      case LinkMenuAction.remove:
        final range = getLinkRange(node);
        state.refs.editorController.formatText(
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
