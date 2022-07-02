import 'package:flutter/material.dart';

import '../../shared/state/editor.state.dart';
import '../models/base/text-boundary.model.dart';

class ExtendSelectionOrCaretPositionAction extends ContextAction<
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent> {
  final EditorState state;
  final TextBoundaryM Function(
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent intent,
    EditorState state,
  ) getTextBoundariesForIntent;

  ExtendSelectionOrCaretPositionAction(
    this.getTextBoundariesForIntent,
    this.state,
  );

  @override
  Object? invoke(
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent intent, [
    BuildContext? context,
  ]) {
    final selection =
        state.refs.editorController.plainTextEditingValue.selection;

    assert(selection.isValid);

    final textBoundary = getTextBoundariesForIntent(intent, state);
    final textBoundarySelection = textBoundary.textEditingValue.selection;

    if (!textBoundarySelection.isValid) {
      return null;
    }

    final extent = textBoundarySelection.extent;
    final newExtent = intent.forward
        ? textBoundary.getTrailingTextBoundaryAt(extent)
        : textBoundary.getLeadingTextBoundaryAt(extent);

    final newSelection = (newExtent.offset - textBoundarySelection.baseOffset) *
                (textBoundarySelection.extentOffset -
                    textBoundarySelection.baseOffset) <
            0
        ? textBoundarySelection.copyWith(
            extentOffset: textBoundarySelection.baseOffset,
            affinity: textBoundarySelection.extentOffset >
                    textBoundarySelection.baseOffset
                ? TextAffinity.downstream
                : TextAffinity.upstream,
          )
        : textBoundarySelection.extendTo(newExtent);

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
      state.editorConfig.config.enableInteractiveSelection &&
      state.refs.editorController.plainTextEditingValue.selection.isValid;
}
