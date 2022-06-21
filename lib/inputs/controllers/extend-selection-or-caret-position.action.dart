import 'package:flutter/material.dart';

import '../../controller/services/editor-text.service.dart';
import '../../editor/state/editor-config.state.dart';
import '../models/base/text-boundary.model.dart';

class ExtendSelectionOrCaretPositionAction extends ContextAction<
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent> {
  final _editorTextService = EditorTextService();
  final _editorConfigState = EditorConfigState();

  final TextBoundaryM Function(
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent intent,
  ) getTextBoundariesForIntent;

  ExtendSelectionOrCaretPositionAction(
    this.getTextBoundariesForIntent,
  );

  @override
  Object? invoke(
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent intent, [
    BuildContext? context,
  ]) {
    final selection = _editorTextService.textEditingValue.selection;

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
      _editorTextService.textEditingValue.selection.isValid;
}
