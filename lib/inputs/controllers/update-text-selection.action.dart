import 'package:flutter/material.dart';

import '../../controller/services/editor-text.service.dart';
import '../../editor/state/editor-config.state.dart';
import '../models/base/text-boundary.model.dart';

class UpdateTextSelectionAction<T extends DirectionalCaretMovementIntent>
    extends ContextAction<T> {
  final _editorTextService = EditorTextService();
  final _editorConfigState = EditorConfigState();

  final bool ignoreNonCollapsedSelection;
  final TextBoundaryM Function(T intent) getTextBoundariesForIntent;

  UpdateTextSelectionAction(
    this.ignoreNonCollapsedSelection,
    this.getTextBoundariesForIntent,
  );

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    final selection = _editorTextService.textEditingValue.selection;

    assert(selection.isValid);

    final collapseSelection = intent.collapseSelection ||
        !_editorConfigState.config.enableInteractiveSelection;

    // Collapse to the logical start/end.
    TextSelection _collapse(TextSelection selection) {
      assert(selection.isValid);
      assert(!selection.isCollapsed);

      return selection.copyWith(
        baseOffset: intent.forward ? selection.end : selection.start,
        extentOffset: intent.forward ? selection.end : selection.start,
      );
    }

    if (!selection.isCollapsed &&
        !ignoreNonCollapsedSelection &&
        collapseSelection) {
      return Actions.invoke(
        context!,
        UpdateSelectionIntent(
          _editorTextService.textEditingValue,
          _collapse(selection),
          SelectionChangedCause.keyboard,
        ),
      );
    }

    final textBoundary = getTextBoundariesForIntent(intent);
    final textBoundarySelection = textBoundary.textEditingValue.selection;

    if (!textBoundarySelection.isValid) {
      return null;
    }

    if (!textBoundarySelection.isCollapsed &&
        !ignoreNonCollapsedSelection &&
        collapseSelection) {
      return Actions.invoke(
        context!,
        UpdateSelectionIntent(
          _editorTextService.textEditingValue,
          _collapse(textBoundarySelection),
          SelectionChangedCause.keyboard,
        ),
      );
    }

    final extent = textBoundarySelection.extent;
    final newExtent = intent.forward
        ? textBoundary.getTrailingTextBoundaryAt(extent)
        : textBoundary.getLeadingTextBoundaryAt(extent);

    final newSelection = collapseSelection
        ? TextSelection.fromPosition(newExtent)
        : textBoundarySelection.extendTo(newExtent);

    // If collapseAtReversal is true and would have an effect, collapse it.
    if (!selection.isCollapsed &&
        intent.collapseAtReversal &&
        (selection.baseOffset < selection.extentOffset !=
            newSelection.baseOffset < newSelection.extentOffset)) {
      return Actions.invoke(
        context!,
        UpdateSelectionIntent(
          _editorTextService.textEditingValue,
          TextSelection.fromPosition(selection.base),
          SelectionChangedCause.keyboard,
        ),
      );
    }

    return Actions.invoke(
      context!,
      UpdateSelectionIntent(
        textBoundary.textEditingValue,
        newSelection,
        SelectionChangedCause.keyboard,
      ),
    );
  }

  @override
  bool get isActionEnabled =>
      _editorTextService.textEditingValue.selection.isValid;
}
