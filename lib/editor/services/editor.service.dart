import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controller/state/editor-controller.state.dart';
import '../../cursor/services/caret.service.dart';
import '../../cursor/state/cursor-controller.state.dart';
import '../../inputs/services/input-connection.service.dart';
import '../../selection/services/selection-actions.service.dart';
import '../state/editor-state-widget.state.dart';
import '../state/focus-node.state.dart';
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

    _editorStateWidgetState.editor.selectionActionsController?.dispose();
    _editorStateWidgetState.editor.selectionActionsController = null;
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
