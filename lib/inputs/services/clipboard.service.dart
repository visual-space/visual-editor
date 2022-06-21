import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controller/services/editor-text.service.dart';
import '../../controller/state/editor-controller.state.dart';
import '../../controller/state/paste.state.dart';
import '../../cursor/services/cursor.service.dart';
import '../../documents/models/nodes/block-embed.model.dart';
import '../../documents/models/styling-attributes.dart';
import '../../editor/state/editor-config.state.dart';
import '../../embeds/services/image.utils.dart';
import '../../selection/services/selection-actions.service.dart';

// Handles all the clipboard operations, cut, copy, paste
class ClipboardService {
  final _editorControllerState = EditorControllerState();
  final _selectionActionsService = SelectionActionsService();
  final _editorConfigState = EditorConfigState();
  final _editorTextService = EditorTextService();
  final _cursorService = CursorService();
  final _pasteState = PasteState();

  static final _instance = ClipboardService._privateConstructor();

  factory ClipboardService() => _instance;

  ClipboardService._privateConstructor();

  void copySelection(
    SelectionChangedCause cause,
  ) {
    final controller = _editorControllerState.controller;

    controller.copiedImageUrl = null;
    _pasteState.setPastePlainText(controller.getPlainText());
    _pasteState.setPasteStyle(
      controller.getAllIndividualSelectionStyles(),
    );

    final selection = _editorTextService.textEditingValue.selection;
    final text = _editorTextService.textEditingValue.text;

    if (selection.isCollapsed) {
      return;
    }

    Clipboard.setData(
      ClipboardData(
        text: selection.textInside(text),
      ),
    );

    if (cause == SelectionChangedCause.toolbar) {
      _cursorService.bringIntoView(
        _editorTextService.textEditingValue.selection.extent,
      );

      // Collapse the selection and hide the buttons and handles.
      _editorTextService.userUpdateTextEditingValue(
        TextEditingValue(
          text: _editorTextService.textEditingValue.text,
          selection: TextSelection.collapsed(
            offset: _editorTextService.textEditingValue.selection.end,
          ),
        ),
        SelectionChangedCause.toolbar,
      );
    }
  }

  void cutSelection(
    SelectionChangedCause cause,
  ) {
    final controller = _editorControllerState.controller;

    controller.copiedImageUrl = null;
    _pasteState.setPastePlainText(controller.getPlainText());
    _pasteState.setPasteStyle(
      controller.getAllIndividualSelectionStyles(),
    );

    if (_editorConfigState.config.readOnly) {
      return;
    }

    final selection = _editorTextService.textEditingValue.selection;
    final text = _editorTextService.textEditingValue.text;

    if (selection.isCollapsed) {
      return;
    }

    Clipboard.setData(ClipboardData(text: selection.textInside(text)));
    replaceText(
      ReplaceTextIntent(
        _editorTextService.textEditingValue,
        '',
        selection,
        cause,
      ),
    );

    if (cause == SelectionChangedCause.toolbar) {
      _cursorService.bringIntoView(
        _editorTextService.textEditingValue.selection.extent,
      );
      _selectionActionsService.hideToolbar();
    }
  }

  Future<void> pasteText(
    SelectionChangedCause cause,
  ) async {
    if (_editorConfigState.config.readOnly) {
      return;
    }

    final controller = _editorControllerState.controller;

    if (controller.copiedImageUrl != null) {
      final index = _editorTextService.textEditingValue.selection.baseOffset;
      final length =
          _editorTextService.textEditingValue.selection.extentOffset - index;
      final copied = controller.copiedImageUrl!;

      controller.replaceText(
        index,
        length,
        BlockEmbedM.image(copied.item1),
        null,
      );

      if (copied.item2.isNotEmpty) {
        controller.formatText(
          getImageNode(controller, index + 1).item1,
          1,
          StyleAttributeM(copied.item2),
        );
      }

      controller.copiedImageUrl = null;
      await Clipboard.setData(
        const ClipboardData(text: ''),
      );

      return;
    }

    final selection = _editorTextService.textEditingValue.selection;

    if (!selection.isValid) {
      return;
    }

    // Snapshot the input before using `await`.
    // See https://github.com/flutter/flutter/issues/11427
    final data = await Clipboard.getData(Clipboard.kTextPlain);

    if (data == null) {
      return;
    }

    replaceText(
      ReplaceTextIntent(
        _editorTextService.textEditingValue,
        data.text!,
        selection,
        cause,
      ),
    );

    _cursorService.bringIntoView(
      _editorTextService.textEditingValue.selection.extent,
    );

    // Collapse the selection and hide the buttons and handles.
    _editorTextService.userUpdateTextEditingValue(
      TextEditingValue(
        text: _editorTextService.textEditingValue.text,
        selection: TextSelection.collapsed(
          offset: _editorTextService.textEditingValue.selection.end,
        ),
      ),
      cause,
    );
  }

  ToolbarOptions toolbarOptions() {
    final enable = _editorConfigState.config.enableInteractiveSelection;

    return ToolbarOptions(
      copy: enable,
      cut: enable,
      paste: enable,
      selectAll: enable,
    );
  }

  bool cutEnabled() =>
      toolbarOptions().cut && !_editorConfigState.config.readOnly;

  bool copyEnabled() => toolbarOptions().copy;

  bool pasteEnabled() =>
      toolbarOptions().paste && !_editorConfigState.config.readOnly;

  void replaceText(ReplaceTextIntent intent) {
    _editorTextService.userUpdateTextEditingValue(
      intent.currentTextEditingValue.replaced(
        intent.replacementRange,
        intent.replacementText,
      ),
      intent.cause,
    );
  }
}
