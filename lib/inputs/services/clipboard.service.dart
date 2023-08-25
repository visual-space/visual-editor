import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../cursor/services/caret.service.dart';
import '../../document/models/attributes/attributes.model.dart';
import '../../document/models/attributes/styling-attributes.dart';
import '../../document/models/nodes/embed.model.dart';
import '../../editor/services/editor.service.dart';
import '../../embeds/const/embeds.const.dart';
import '../../embeds/models/image.model.dart';
import '../../embeds/services/embeds.service.dart';
import '../../selection/services/selection-handles.service.dart';
import '../../shared/state/editor.state.dart';
import '../../styles/services/styles.service.dart';

// Handles all the clipboard operations, cut, copy, paste
class ClipboardService {
  late final EditorService _editorService;
  late final StylesService _stylesService;
  late final CaretService _caretService;
  late final EmbedsService _embedsService;

  final EditorState state;

  ClipboardService(this.state) {
    _editorService = EditorService(state);
    _stylesService = StylesService(state);
    _caretService = CaretService(state);
    _embedsService = EmbedsService(state);
  }

  void copySelection(SelectionChangedCause cause) {
    state.paste.copiedImageUrl = null;
    // TODO This code must be double checked and restored. We need to restore copy paste to preserver markers.
    state.paste.plainText = _editorService.getSelectionPlainText();
    state.paste.styles = _stylesService.getAllIndividualSelectionStyles();

    final plainText = _editorService.plainText;
    final selection = plainText.selection;

    if (selection.isCollapsed) {
      return;
    }

    Clipboard.setData(
      ClipboardData(
        text: selection.textInside(plainText.text),
      ),
    );

    if (cause == SelectionChangedCause.toolbar) {
      _caretService.bringIntoView(selection.extent);

      // Collapse the selection and hide the buttons and handles.
      _editorService.removeSpecialCharsAndUpdateDocTextAndStyle(
        TextEditingValue(
          text: plainText.text,
          selection: TextSelection.collapsed(
            offset: selection.end,
          ),
        ),
        SelectionChangedCause.toolbar,
      );
    }
  }

  // If selection contains a link, copy to clipboard the link url.
  void copySelectionLinkUrl() {
    final selectionHasLink = _stylesService.getSelectionStyle().attributes.containsKey('link');

    if (selectionHasLink) {
      final linkUrl = _stylesService
          .getSelectionStyle()
          .attributes[AttributesM.link.key]
          ?.value;

      Clipboard.setData(
        ClipboardData(
          text: linkUrl,
        ),
      );
    }
  }

  void cutSelection(
    SelectionChangedCause cause,
    HideToolbarCallback hideToolbar,
  ) {
    // TODO This code must be double checked and restored. We need to restore copy paste to preserver markers.
    state.paste.plainText = _editorService.getSelectionPlainText();
    state.paste.styles = _stylesService.getAllIndividualSelectionStyles();
    state.paste.copiedImageUrl = null;

    if (state.config.readOnly) {
      return;
    }

    final plainText = _editorService.plainText;
    final selection = plainText.selection;

    if (selection.isCollapsed) {
      return;
    }

    Clipboard.setData(ClipboardData(
      text: selection.textInside(plainText.text),
    ));
    removeSpecialCharsAndUpdateDocTextAndStyle(
      ReplaceTextIntent(plainText, '', selection, cause),
    );

    if (cause == SelectionChangedCause.toolbar) {
      _caretService.bringIntoView(selection.extent);
      hideToolbar();
    }
  }

  Future<void> pasteText(SelectionChangedCause cause) async {
    if (state.config.readOnly) {
      return;
    }

    final plainText = _editorService.plainText;
    final selection = plainText.selection;

    if (state.paste.copiedImageUrl != null) {
      final index = selection.baseOffset;
      final length = selection.extentOffset - index;
      final copied = state.paste.copiedImageUrl!;
      final imgEmbed = EmbedM(IMAGE_EMBED_TYPE, copied.imageUrl);

      _editorService.replace(index, length, imgEmbed, null);

      if (copied.style.isNotEmpty) {
        final offset = _embedsService.getEmbedOffset().offset;
        final newStyle = StyleAttributeM(copied.style);

        _stylesService.formatTextRange(offset, 1, newStyle);
      }

      state.paste.copiedImageUrl = null;
      await Clipboard.setData(
        const ClipboardData(text: ''),
      );

      return;
    }

    if (!selection.isValid) {
      return;
    }

    // Snapshot the input before using `await`.
    // See https://github.com/flutter/flutter/issues/11427
    final data = await Clipboard.getData(Clipboard.kTextPlain);

    if (data == null) {
      return;
    }

    removeSpecialCharsAndUpdateDocTextAndStyle(
      ReplaceTextIntent(plainText, data.text!, selection, cause),
    );

    _caretService.bringIntoView(selection.extent);

    // Collapse the selection and hide the buttons and handles.
    _editorService.removeSpecialCharsAndUpdateDocTextAndStyle(
      TextEditingValue(
        text: plainText.text,
        selection: TextSelection.collapsed(
          offset: selection.end,
        ),
      ),
      cause,
    );
  }

  ToolbarOptions toolbarOptions() {
    final enable = state.config.enableInteractiveSelection;

    return ToolbarOptions(
      copy: enable,
      cut: enable,
      paste: enable,
      selectAll: enable,
    );
  }

  bool cutEnabled() {
    return toolbarOptions().cut && !state.config.readOnly;
  }

  bool copyEnabled() {
    return toolbarOptions().copy;
  }

  bool pasteEnabled() {
    return toolbarOptions().paste && !state.config.readOnly;
  }

  void removeSpecialCharsAndUpdateDocTextAndStyle(ReplaceTextIntent intent) {
    _editorService.removeSpecialCharsAndUpdateDocTextAndStyle(
      intent.currentTextEditingValue.replaced(
        intent.replacementRange,
        intent.replacementText,
      ),
      intent.cause,
    );
  }

  void setCopiedImageUrl(ImageM image) {
    state.paste.copiedImageUrl = image;
  }
}
