import 'package:flutter/material.dart';

import '../../../controller/services/editor-text.service.dart';
import '../../../controller/state/editor-controller.state.dart';
import '../../services/vertical-caret-movement-run.dart';
import '../../state/editor-config.state.dart';
import '../../widgets/editor-renderer.dart';

// +++ DOC
class UpdateTextSelectionToAdjacentLineAction<
    T extends DirectionalCaretMovementIntent> extends ContextAction<T> {
  final _editorTextService = EditorTextService();
  final _editorConfigState = EditorConfigState();
  final _editorControllerState = EditorControllerState();

  final EditorRenderer editorRenderer;

  UpdateTextSelectionToAdjacentLineAction(this.editorRenderer);

  EditorVerticalCaretMovementRun? _verticalMovementRun;
  TextSelection? _runSelection;

  void stopCurrentVerticalRunIfSelectionChanges() {
    final runSelection = _runSelection;

    if (runSelection == null) {
      assert(_verticalMovementRun == null);
      return;
    }

    _runSelection = _editorTextService.textEditingValue.selection;
    final currentSelection = _editorControllerState.controller.selection;
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
    assert(_editorTextService.textEditingValue.selection.isValid);

    final collapseSelection = intent.collapseSelection ||
        !_editorConfigState.config.enableInteractiveSelection;
    final value = _editorTextService.textEditingValue;

    if (!value.selection.isValid) {
      return;
    }

    final currentRun = _verticalMovementRun ??
        editorRenderer.startVerticalCaretMovement(
          editorRenderer.selection.extent,
        );

    final shouldMove =
        intent.forward ? currentRun.moveNext() : currentRun.movePrevious();
    final newExtent = shouldMove
        ? currentRun.current
        : (intent.forward
            ? TextPosition(
                offset: _editorTextService.textEditingValue.text.length)
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

    if (_editorTextService.textEditingValue.selection == newSelection) {
      _verticalMovementRun = currentRun;
      _runSelection = newSelection;
    }
  }

  @override
  bool get isActionEnabled =>
      _editorTextService.textEditingValue.selection.isValid;
}
