import 'package:flutter/material.dart';

import '../../editor/controllers/vertical-caret-movement-run.controller.dart';
import '../../editor/services/editor.service.dart';
import '../../shared/state/editor.state.dart';

// TODO Document. At the moment it's quite unclear what this action does.
//   Seems to be in charge of deciding where the cursor lands next when moving it up or down.
//   It's unclear how or when it runs if at all.
//   Seems to be activated when long tap is used to select text on mobiles.
//
// Used on mobiles only.
class UpdateTextSelectionToAdjacentLineAction<
    T extends DirectionalCaretMovementIntent> extends ContextAction<T> {
  late final EditorService _editorService;

  final EditorState state;

  UpdateTextSelectionToAdjacentLineAction(this.state) {
    _editorService = EditorService(state);
  }

  VerticalCaretMovementRunController? _verticalMovementRun;
  TextSelection? _runSelection;

  void stopCurrentVerticalRunIfSelectionChanges() {
    final selection = _editorService.plainText.selection;
    final prevRunSelection = _runSelection;

    if (prevRunSelection == null) {
      assert(_verticalMovementRun == null);
      return;
    }

    _runSelection = selection;
    final currentSelection = state.selection.selection;
    final continueCurrentRun = currentSelection.isValid &&
        currentSelection.isCollapsed &&
        currentSelection.baseOffset == prevRunSelection.baseOffset &&
        currentSelection.extentOffset == prevRunSelection.extentOffset;

    if (!continueCurrentRun) {
      _verticalMovementRun = null;
      _runSelection = null;
    }
  }

  @override
  void invoke(T intent, [BuildContext? context]) {
    final plainText = _editorService.plainText;
    final selection = plainText.selection;
    assert(selection.isValid);

    final collapseSelection =
        intent.collapseSelection || state.config.enableInteractiveSelection;

    if (!selection.isValid) {
      return;
    }

    final currentRun = _verticalMovementRun ??
        state.refs.renderer.startVerticalCaretMovement(
          state.selection.selection.extent,
        );

    final shouldMove =
        intent.forward ? currentRun.moveNext() : currentRun.movePrevious();
    final newExtent = shouldMove
        ? currentRun.current
        : (intent.forward
            ? TextPosition(offset: plainText.text.length)
            : const TextPosition(offset: 0));
    final newSelection = collapseSelection
        ? TextSelection.fromPosition(newExtent)
        : selection.extendTo(newExtent);

    Actions.invoke(
      context!,
      UpdateSelectionIntent(
        plainText,
        newSelection,
        SelectionChangedCause.keyboard,
      ),
    );

    if (selection == newSelection) {
      _verticalMovementRun = currentRun;
      _runSelection = newSelection;
    }
  }

  @override
  bool get isActionEnabled => _editorService.plainText.selection.isValid;
}
