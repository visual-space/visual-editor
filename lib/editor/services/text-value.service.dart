import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../cursor/services/caret.service.dart';
import '../../inputs/controllers/update-text-selection-to-adjiacent-line.action.dart';
import '../../inputs/services/input-connection.service.dart';
import '../../inputs/services/keyboard.service.dart';
import '../../selection/services/selection-actions.service.dart';
import '../../shared/state/editor.state.dart';

class TextValueService {
  final _textConnectionService = InputConnectionService();
  final _selectionActionsService = SelectionActionsService();
  final _keyboardService = KeyboardService();
  final _caretService = CaretService();

  static final _instance = TextValueService._privateConstructor();

  factory TextValueService() => _instance;

  TextValueService._privateConstructor();

  // Any interaction:
  // - Changing cursor position
  // - Changing selection range
  // - Adding styles
  // - Adding characters
  // - Undo redo
  void updateEditor(EditorState state) {
    final ignoreFocus = state.refreshEditor.ignoreFocusOnTextChange;

    if (kIsWeb) {
      onChangeTextEditingValue(ignoreFocus, state);

      if (!ignoreFocus) {
        _keyboardService.requestKeyboard(state);
      }

      return;
    }

    if (ignoreFocus || state.keyboardVisible.isVisible) {
      onChangeTextEditingValue(ignoreFocus, state);
    } else {
      _keyboardService.requestKeyboard(state);

      if (state.refs.editorState.mounted) {
        state.refs.editorState.refresh();
      }
    }

    UpdateTextSelectionToAdjacentLineAction<
            ExtendSelectionVerticallyToAdjacentLineIntent>(state)
        .stopCurrentVerticalRunIfSelectionChanges();
  }

  // Triggers the build cycle for the editor when the text changes.
  // It also updates the remote value from the connected system input (Read more in the InputConnectionService).
  // Displays the caret on screen and prevents blinking while typing.
  void onChangeTextEditingValue(bool ignoreCaret, EditorState state) {
    _textConnectionService.updateRemoteValueIfNeeded(state);

    // When dispatching replaceText() from the controller if is possible to skip over the code
    // that handles the placement and activation of the caret.
    if (!ignoreCaret) {
      _caretService.showCaretOnScreen(state);
      state.refs.cursorController.startOrStopCursorTimerIfNeeded(
        state.refs.editorController.selection,
      );

      if (_textConnectionService.hasConnection) {
        // To keep the cursor from blinking while typing, we want to restart the
        // cursor timer every time a new character is typed.
        state.refs.cursorController
          ..stopCursorTimer(resetCharTicks: false)
          ..startCursorTimer();
      }

      // Refresh selection overlay after the build step had a chance to
      // update and register all children of RenderEditor.
      // Otherwise this will fail in situations where a new line of text is entered, which adds a new RenderEditableBox child.
      // If we try to update selection overlay immediately it'll not be able to find
      // the new child since it hasn't been built yet.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!state.refs.editorState.mounted) {
          return;
        }

        _selectionActionsService.updateOrDisposeSelectionOverlayIfNeeded(state);
      });
    }

    // Trigger the build() method in the editor to update the children widgets of the editor widget
    if (state.refs.editorState.mounted) {
      state.refs.editorState.refresh();
    }
  }
}
