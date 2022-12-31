import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controller/services/editor-text.service.dart';
import '../../cursor/services/cursor.service.dart';
import '../../documents/models/attributes/styling-attributes.dart';
import '../../embeds/const/embeds.const.dart';
import '../../embeds/services/embed.utils.dart';
import '../../selection/services/selection-actions.service.dart';
import '../../shared/state/editor.state.dart';
import '../../visual-editor.dart';

// Handles all the clipboard operations, cut, copy, paste
class ClipboardService {
  final _selectionActionsService = SelectionActionsService();
  final _editorTextService = EditorTextService();
  final _cursorService = CursorService();
  final _embedUtils = EmbedUtils();

  static final _instance = ClipboardService._privateConstructor();

  factory ClipboardService() => _instance;

  ClipboardService._privateConstructor();

  void copySelection(
    SelectionChangedCause cause,
    EditorState state,
  ) {
    final controller = state.refs.editorController;

    controller.copiedImageUrl = null;
    state.paste.setPastePlainText(controller.getPlainText());
    state.paste.setPasteStyle(
      controller.getAllIndividualSelectionStyles(),
    );

    final selection =
        state.refs.editorController.plainTextEditingValue.selection;
    final text = state.refs.editorController.plainTextEditingValue.text;

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
        state.refs.editorController.plainTextEditingValue.selection.extent,
        state,
      );

      // Collapse the selection and hide the buttons and handles.
      _editorTextService.userUpdateTextEditingValue(
        TextEditingValue(
          text: state.refs.editorController.plainTextEditingValue.text,
          selection: TextSelection.collapsed(
            offset:
                state.refs.editorController.plainTextEditingValue.selection.end,
          ),
        ),
        SelectionChangedCause.toolbar,
        state,
      );
    }
  }

  void cutSelection(
    SelectionChangedCause cause,
    EditorState state,
  ) {
    final controller = state.refs.editorController;

    controller.copiedImageUrl = null;
    state.paste.setPastePlainText(controller.getPlainText());
    state.paste.setPasteStyle(
      controller.getAllIndividualSelectionStyles(),
    );

    if (state.editorConfig.config.readOnly) {
      return;
    }

    final selection =
        state.refs.editorController.plainTextEditingValue.selection;
    final text = state.refs.editorController.plainTextEditingValue.text;

    if (selection.isCollapsed) {
      return;
    }

    Clipboard.setData(ClipboardData(text: selection.textInside(text)));
    replaceText(
      ReplaceTextIntent(
        state.refs.editorController.plainTextEditingValue,
        '',
        selection,
        cause,
      ),
      state,
    );

    if (cause == SelectionChangedCause.toolbar) {
      _cursorService.bringIntoView(
        state.refs.editorController.plainTextEditingValue.selection.extent,
        state,
      );
      _selectionActionsService.hideToolbar(state);
    }
  }

  Future<void> pasteText(
    SelectionChangedCause cause,
    EditorState state,
  ) async {
    if (state.editorConfig.config.readOnly) {
      return;
    }

    final controller = state.refs.editorController;

    if (controller.copiedImageUrl != null) {
      final index = state
          .refs.editorController.plainTextEditingValue.selection.baseOffset;
      final length = state.refs.editorController.plainTextEditingValue.selection
              .extentOffset -
          index;
      final copied = controller.copiedImageUrl!;

      controller.replaceText(
        index,
        length,
        EmbedM(IMAGE_EMBED_TYPE, copied.imageUrl),
        null,
      );

      if (copied.style.isNotEmpty) {
        controller.formatText(
          _embedUtils.getEmbedOffset(controller: controller).offset,
          1,
          StyleAttributeM(copied.style),
        );
      }

      controller.copiedImageUrl = null;
      await Clipboard.setData(
        const ClipboardData(text: ''),
      );

      return;
    }

    final selection =
        state.refs.editorController.plainTextEditingValue.selection;

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
        state.refs.editorController.plainTextEditingValue,
        data.text!,
        selection,
        cause,
      ),
      state,
    );

    _cursorService.bringIntoView(
      state.refs.editorController.plainTextEditingValue.selection.extent,
      state,
    );

    // Collapse the selection and hide the buttons and handles.
    _editorTextService.userUpdateTextEditingValue(
      TextEditingValue(
        text: state.refs.editorController.plainTextEditingValue.text,
        selection: TextSelection.collapsed(
          offset:
              state.refs.editorController.plainTextEditingValue.selection.end,
        ),
      ),
      cause,
      state,
    );
  }

  ToolbarOptions toolbarOptions(EditorState state) {
    final enable = state.editorConfig.config.enableInteractiveSelection;

    return ToolbarOptions(
      copy: enable,
      cut: enable,
      paste: enable,
      selectAll: enable,
    );
  }

  bool cutEnabled(EditorState state) =>
      toolbarOptions(state).cut && !state.editorConfig.config.readOnly;

  bool copyEnabled(EditorState state) => toolbarOptions(state).copy;

  bool pasteEnabled(EditorState state) =>
      toolbarOptions(state).paste && !state.editorConfig.config.readOnly;

  void replaceText(ReplaceTextIntent intent, EditorState state) {
    _editorTextService.userUpdateTextEditingValue(
      intent.currentTextEditingValue.replaced(
        intent.replacementRange,
        intent.replacementText,
      ),
      intent.cause,
      state,
    );
  }
}
