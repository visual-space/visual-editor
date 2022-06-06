import 'package:flutter/material.dart';

import '../../models/boundaries/text-boundary.model.dart';
import '../../state/editor-config.state.dart';
import '../../widgets/raw-editor.dart';

// +++ DOC
class ExtendSelectionOrCaretPositionAction extends ContextAction<
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent> {
  final _editorConfigState = EditorConfigState();

  ExtendSelectionOrCaretPositionAction(
    this.state,
    this.getTextBoundariesForIntent,
  );

  final RawEditorState state; // +++ DELETE all state refs (use services)
  final TextBoundaryM Function(
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent intent,
  ) getTextBoundariesForIntent;

  @override
  Object? invoke(
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent intent, [
    BuildContext? context,
  ]) {
    final selection = state.textEditingValue.selection;
    assert(selection.isValid);

    final textBoundary = getTextBoundariesForIntent(intent);
    final textBoundarySelection = textBoundary.textEditingValue.selection;
    if (!textBoundarySelection.isValid) {
      return null;
    }

    final extent = textBoundarySelection.extent;
    final newExtent = intent.forward
        ? textBoundary.getTrailingTextBoundaryAt(extent)
        : textBoundary.getLeadingTextBoundaryAt(extent);

    // +++ ALIASES
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
      _editorConfigState.config.enableInteractiveSelection &&
      state.textEditingValue.selection.isValid;
}
