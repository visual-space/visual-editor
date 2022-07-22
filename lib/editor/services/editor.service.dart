import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../cursor/services/caret.service.dart';
import '../../inputs/services/input-connection.service.dart';
import '../../selection/services/selection-actions.service.dart';
import '../../shared/state/editor.state.dart';

class EditorService {
  final _textConnectionService = InputConnectionService();
  final _selectionActionsService = SelectionActionsService();
  final _caretService = CaretService();

  static final _instance = EditorService._privateConstructor();

  factory EditorService() => _instance;

  EditorService._privateConstructor();

  void handleFocusChanged(EditorState state) {
    final editor = state.refs.editorState;

    _textConnectionService.openOrCloseConnection(state);
    state.refs.cursorController.startOrStopCursorTimerIfNeeded(
      state.refs.editorController.selection,
    );
    _selectionActionsService.updateOrDisposeSelectionOverlayIfNeeded(state);

    if (state.refs.focusNode.hasFocus) {
      WidgetsBinding.instance.addObserver(
        editor,
      );
      _caretService.showCaretOnScreen(state);
    } else {
      WidgetsBinding.instance.removeObserver(
        editor,
      );
    }

    editor.safeUpdateKeepAlive();
  }

  void disposeEditor(EditorState state) {
    final editor = state.refs.editorState;

    _textConnectionService.closeConnectionIfNeeded();
    editor.keyboardVisibilitySub?.cancel();
    HardwareKeyboard.instance.removeHandler(editor.hardwareKeyboardEvent);

    assert(!_textConnectionService.hasConnection);

    editor.selectionActionsController?.dispose();
    editor.selectionActionsController = null;
    editor.editorUpdatesListener?.cancel();
    state.refs.focusNode.removeListener(
      state.refs.editorState.handleFocusChanged,
    );
    state.refs.cursorController.dispose();
    editor.clipboardStatus
      ..removeListener(editor.onChangedClipboardStatus)
      ..dispose();
  }
}
