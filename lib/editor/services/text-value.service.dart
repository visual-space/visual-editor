import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../controller/state/editor-controller.state.dart';
import '../../cursor/state/cursor-controller.state.dart';
import '../../inputs/services/keyboard.service.dart';
import '../../inputs/state/keyboard-visible.state.dart';
import '../../selection/services/selection-actions.service.dart';
import '../state/editor-state-widget.state.dart';
import 'caret.service.dart';
import 'input-connection.service.dart';
import 'keyboard-actions.service.dart';

class TextValueService {
  final _textConnectionService = TextConnectionService();
  final _selectionActionsService = SelectionActionsService();
  final _editorControllerState = EditorControllerState();
  final _cursorControllerState = CursorControllerState();
  final _editorStateWidgetState = EditorStateWidgetState();
  final _keyboardService = KeyboardService();
  final _keyboardActionsService = KeyboardActionsService();
  final _keyboardVisibleState = KeyboardVisibleState();
  final _caretService = CaretService();

  static final _instance = TextValueService._privateConstructor();

  factory TextValueService() => _instance;

  TextValueService._privateConstructor();

  void onChangeTextEditingValue(bool ignoreCaret) {
    _textConnectionService.updateRemoteValueIfNeeded();

    if (ignoreCaret) {
      return;
    }

    _caretService.showCaretOnScreen();
    _cursorControllerState.controller.startOrStopCursorTimerIfNeeded(
      _editorControllerState.controller.selection,
    );

    if (_textConnectionService.hasConnection) {
      // To keep the cursor from blinking while typing, we want to restart the
      // cursor timer every time a new character is typed.
      _cursorControllerState.controller
        ..stopCursorTimer(resetCharTicks: false)
        ..startCursorTimer();
    }

    // Refresh selection overlay after the build step had a chance to
    // update and register all children of RenderEditor.
    // Otherwise this will fail in situations where a new line of text is entered, which adds a new RenderEditableBox child.
    // If we try to update selection overlay immediately it'll not be able to find
    // the new child since it hasn't been built yet.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_editorStateWidgetState.editor.mounted) {
        return;
      }
      _selectionActionsService.updateOrDisposeSelectionOverlayIfNeeded();
    });

    if (_editorStateWidgetState.editor.mounted) {
      _editorStateWidgetState.editor.refresh();
    }
  }

  void onTextEditingValueChanged() {
    final ignoreFocus =
        _editorControllerState.controller.ignoreFocusOnTextChange;

    if (kIsWeb) {
      onChangeTextEditingValue(ignoreFocus);
      if (!ignoreFocus) {
        _keyboardService.requestKeyboard();
      }
      return;
    }

    if (ignoreFocus || _keyboardVisibleState.isVisible) {
      onChangeTextEditingValue(ignoreFocus);
    } else {
      _keyboardService.requestKeyboard();

      if (_editorStateWidgetState.editor.mounted) {
        _editorStateWidgetState.editor.refresh();
      }
    }

    _keyboardActionsService
        .getAdjacentLineAction()
        .stopCurrentVerticalRunIfSelectionChanges();
  }
}
