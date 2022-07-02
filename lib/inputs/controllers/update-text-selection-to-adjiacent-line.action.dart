import 'package:flutter/material.dart';

import '../../editor/controllers/vertical-caret-movement-run.controller.dart';
import '../../shared/state/editor.state.dart';

class UpdateTextSelectionToAdjacentLineAction<
    T extends DirectionalCaretMovementIntent> extends ContextAction<T> {
  final EditorState state;

  UpdateTextSelectionToAdjacentLineAction(
    this.state,
  );

  VerticalCaretMovementRunController? _verticalMovementRun;
  TextSelection? _runSelection;

  void stopCurrentVerticalRunIfSelectionChanges() {
    final prevRunSelection = _runSelection;

    if (prevRunSelection == null) {
      assert(_verticalMovementRun == null);
      return;
    }

    _runSelection = state.refs.editorController.plainTextEditingValue.selection;
    final currentSelection = state.refs.editorController.selection;
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
    assert(state.refs.editorController.plainTextEditingValue.selection.isValid);

    final collapseSelection = intent.collapseSelection ||
        state.editorConfig.config.enableInteractiveSelection;
    final value = state.refs.editorController.plainTextEditingValue;

    if (!value.selection.isValid) {
      return;
    }

    final currentRun = _verticalMovementRun ??
        state.refs.renderer.startVerticalCaretMovement(
          state.refs.editorController.selection.extent,
        );

    final shouldMove =
        intent.forward ? currentRun.moveNext() : currentRun.movePrevious();
    final newExtent = shouldMove
        ? currentRun.current
        : (intent.forward
            ? TextPosition(
                offset: state
                    .refs.editorController.plainTextEditingValue.text.length,
              )
            : const TextPosition(offset: 0));
    final newSelection = collapseSelection
        ? TextSelection.fromPosition(newExtent)
        : value.selection.extendTo(newExtent);

    Actions.invoke(
      context!,
      UpdateSelectionIntent(
        value,
        newSelection,
        SelectionChangedCause.keyboard,
      ),
    );

    if (state.refs.editorController.plainTextEditingValue.selection ==
        newSelection) {
      _verticalMovementRun = currentRun;
      _runSelection = newSelection;
    }
  }

  @override
  bool get isActionEnabled =>
      state.refs.editorController.plainTextEditingValue.selection.isValid;
}
