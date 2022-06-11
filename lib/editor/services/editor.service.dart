import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controller/state/editor-controller.state.dart';
import '../../cursor/state/cursor-controller.state.dart';
import '../../selection/services/selection-actions.service.dart';
import '../state/editor-state-widget.state.dart';
import '../state/focus-node.state.dart';
import 'caret.service.dart';
import 'input-connection.service.dart';
import 'text-value.service.dart';

class EditorService {
  final _textConnectionService = TextConnectionService();
  final _selectionActionsService = SelectionActionsService();
  final _editorControllerState = EditorControllerState();
  final _cursorControllerState = CursorControllerState();
  final _focusNodeState = FocusNodeState();
  final _editorStateWidgetState = EditorStateWidgetState();
  final _textValueService = TextValueService();
  final _caretService = CaretService();

  static final _instance = EditorService._privateConstructor();

  factory EditorService() => _instance;

  EditorService._privateConstructor();

  void handleFocusChanged() {
    _textConnectionService.openOrCloseConnection();
    _cursorControllerState.controller.startOrStopCursorTimerIfNeeded(
      _editorControllerState.controller.selection,
    );
    _selectionActionsService.updateOrDisposeSelectionOverlayIfNeeded();

    if (_focusNodeState.node.hasFocus) {
      WidgetsBinding.instance.addObserver(
        _editorStateWidgetState.editor,
      );
      _caretService.showCaretOnScreen();
    } else {
      WidgetsBinding.instance.removeObserver(
        _editorStateWidgetState.editor,
      );
    }

    _editorStateWidgetState.editor.safeUpdateKeepAlive();
  }

  void disposeEditor() {
    final editor = _editorStateWidgetState.editor;

    _textConnectionService.closeConnectionIfNeeded();
    editor.keyboardVisibilitySub?.cancel();
    HardwareKeyboard.instance.removeHandler(editor.hardwareKeyboardEvent);

    assert(!_textConnectionService.hasConnection);

    _selectionActionsService.selectionActions?.dispose();
    _selectionActionsService.selectionActions = null;
    _editorControllerState.controller.removeListener(
      _textValueService.onTextEditingValueChanged,
    );
    _focusNodeState.node.removeListener(
      handleFocusChanged,
    );
    _cursorControllerState.controller.dispose();
    editor.clipboardStatus
      ..removeListener(editor.onChangedClipboardStatus)
      ..dispose();
  }
}
