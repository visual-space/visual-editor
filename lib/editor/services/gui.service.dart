import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../cursor/services/caret.service.dart';
import '../../inputs/services/input-connection.service.dart';
import '../../inputs/services/keyboard.service.dart';
import '../../selection/services/selection-handles.service.dart';
import '../../shared/state/editor.state.dart';
import 'editor.service.dart';

// After document model was updated this service updates the text GUI right before triggering the build.
// Requests the soft keyboard. Handles web and mobiles.
// Updates the remote value in the connected system input.
// Displays the caret on screen and prevents blinking while typing.
// Triggers the build cycle for the editor and the toolbar.
// Shows, hides selection controls after the build completed.
// @@@ TODO Copy to docs
class GuiService {
  late final EditorService _editorService;
  late final InputConnectionService _inputConnectionService;
  late final SelectionHandlesService _selectionHandlesService;
  late final KeyboardService _keyboardService;
  late final CaretService _caretService;

  final EditorState state;

  GuiService(this.state) {
    _editorService = EditorService(state);
    _inputConnectionService = InputConnectionService(state);
    _selectionHandlesService = SelectionHandlesService(state);
    _keyboardService = KeyboardService(state);
    _caretService = CaretService(state);
  }

  // === BEFORE BUILD ===

  // Updates the text of the remote input.
  // Requests the soft keyboard.
  // Handles web and mobiles.
  // Triggers the editor build cycle.
  void reqKbUpdateGuiElemsAndBuild(void Function() runBuild) {
    final ignoreFocus = state.runBuild.ignoreFocusOnTextChange;

    if (kIsWeb) {
      updateGuiElementsAndBuild(ignoreFocus, runBuild);

      if (!ignoreFocus) {
        _keyboardService.requestKeyboard();
      }

      return;
    }

    if (ignoreFocus || state.keyboard.isVisible) {
      updateGuiElementsAndBuild(ignoreFocus, runBuild);
    } else {
      // Show software keyboard (on mobiles)
      _keyboardService.requestKeyboard();

      // Trigger the build in editor (main.dart)
      if (state.refs.widget.mounted) {
        runBuild();
      }
    }

    state.refs.adjacentLineAction?.stopCurrentVerticalRunIfSelectionChanges();
  }

  // Updates the remote value in the connected system input.
  // Displays the caret on screen and prevents blinking while typing.
  // Triggers the build cycle for the editor and the toolbar.
  // Shows, hides selection controls after the build completed
  void updateGuiElementsAndBuild(
    bool ignoreCaret,
    void Function() runBuild,
  ) {
    final plainText = _editorService.plainText;
    final selection = state.selection.selection;
    _inputConnectionService.updateRemoteValueIfNeeded(plainText);

    // When dispatching replaceText() from the controller if is possible to skip over the code
    // that handles the placement and activation of the caret.
    if (!ignoreCaret) {
      _caretService.showCaretOnScreen();
      state.refs.cursorController.startOrStopCursorTimerIfNeeded(selection);

      if (_inputConnectionService.hasConnection) {
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
        if (!state.refs.widget.mounted) {
          return;
        }

        final plainText = _editorService.plainText;
        _selectionHandlesService.updateOrDisposeSelectionHandlesIfNeeded(
          plainText,
        );
      });
    }

    // Trigger the build() method in the editor to update the children widgets of the editor widget
    if (state.refs.widget.mounted) {
      runBuild();
    }
  }

  // === FOCUS CHANGE ===

  void updateGuiElemsAfterFocus() {
    final editor = state.refs.widget;
    final plainText = _editorService.plainText;

    // Connect to remote input
    _inputConnectionService.openOrCloseConnection(plainText);

    // Start Caret Timer
    state.refs.cursorController.startOrStopCursorTimerIfNeeded(
      state.selection.selection,
    );

    // Show/ hide selection handles
    _selectionHandlesService.updateOrDisposeSelectionHandlesIfNeeded(plainText);

    // Show caret if focused
    if (state.refs.focusNode.hasFocus) {
      WidgetsBinding.instance.addObserver(editor);
      _caretService.showCaretOnScreen();
    } else {
      WidgetsBinding.instance.removeObserver(editor);
    }

    // Keep Alive
    editor.callUpdateKeepAlive();
  }
}
