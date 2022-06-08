import 'package:flutter/material.dart';

import '../../services/vertical-caret-movement-run.dart';
import '../../state/editor-config.state.dart';
import '../../widgets/raw-editor.dart';

// +++ DOC
class UpdateTextSelectionToAdjacentLineAction<
    T extends DirectionalCaretMovementIntent> extends ContextAction<T> {
  final _editorConfigState = EditorConfigState();

  final RawEditorState state;

  UpdateTextSelectionToAdjacentLineAction(this.state);

  EditorVerticalCaretMovementRun? _verticalMovementRun;
  TextSelection? _runSelection;

  void stopCurrentVerticalRunIfSelectionChanges() {
    final runSelection = _runSelection;

    if (runSelection == null) {
      assert(_verticalMovementRun == null);
      return;
    }

    _runSelection = state.textEditingValue.selection;
    final currentSelection = state.widget.controller.selection;
    final continueCurrentRun = currentSelection.isValid &&
        currentSelection.isCollapsed &&
        currentSelection.baseOffset == runSelection.baseOffset &&
        currentSelection.extentOffset == runSelection.extentOffset;

    if (!continueCurrentRun) {
      _verticalMovementRun = null;
      _runSelection = null;
    }
  }

  @override
  void invoke(T intent, [BuildContext? context]) {
    assert(state.textEditingValue.selection.isValid);

    final collapseSelection = intent.collapseSelection ||
        !_editorConfigState.config.enableInteractiveSelection;
    final value = state.textEditingValue;

    if (!value.selection.isValid) {
      return;
    }

    final currentRun = _verticalMovementRun ??
        state.editorRenderer.startVerticalCaretMovement(
          state.editorRenderer.selection.extent,
        );

    final shouldMove =
        intent.forward ? currentRun.moveNext() : currentRun.movePrevious();
    final newExtent = shouldMove
        ? currentRun.current
        : (intent.forward
            ? TextPosition(offset: state.textEditingValue.text.length)
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

    if (state.textEditingValue.selection == newSelection) {
      _verticalMovementRun = currentRun;
      _runSelection = newSelection;
    }
  }

  @override
  bool get isActionEnabled => state.textEditingValue.selection.isValid;
}
