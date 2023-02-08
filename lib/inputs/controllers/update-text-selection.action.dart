import 'package:flutter/material.dart';

import '../../editor/services/editor.service.dart';
import '../../shared/state/editor.state.dart';
import '../models/base/text-boundary.model.dart';

// TODO Doc
class UpdateTextSelectionAction<T extends DirectionalCaretMovementIntent>
    extends ContextAction<T> {
  late final EditorService _editorService;

  final bool ignoreNonCollapsedSelection;
  final TextBoundaryM Function(T intent) getTextBoundariesForIntent;
  final EditorState state;

  UpdateTextSelectionAction(
    this.ignoreNonCollapsedSelection,
    this.getTextBoundariesForIntent,
    this.state,
  ) {
    _editorService = EditorService(state);
  }

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    final plainText = _editorService.plainText;
    final selection = plainText.selection;

    assert(selection.isValid);

    final collapseSelection =
        intent.collapseSelection || !state.config.enableInteractiveSelection;

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
          plainText,
          _collapse(selection),
          SelectionChangedCause.keyboard,
        ),
      );
    }

    final textBoundary = getTextBoundariesForIntent(intent);
    final textBoundarySelection = textBoundary.plainText.selection;

    if (!textBoundarySelection.isValid) {
      return null;
    }

    if (!textBoundarySelection.isCollapsed &&
        !ignoreNonCollapsedSelection &&
        collapseSelection) {
      return Actions.invoke(
        context!,
        UpdateSelectionIntent(
          plainText,
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
          plainText,
          TextSelection.fromPosition(selection.base),
          SelectionChangedCause.keyboard,
        ),
      );
    }

    return Actions.invoke(
      context!,
      UpdateSelectionIntent(
        textBoundary.plainText,
        newSelection,
        SelectionChangedCause.keyboard,
      ),
    );
  }

  @override
  bool get isActionEnabled {
    return _editorService.plainText.selection.isValid;
  }
}
