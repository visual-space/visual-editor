import 'package:flutter/material.dart';

import '../../editor/services/editor.service.dart';
import '../../shared/state/editor.state.dart';
import '../models/base/text-boundary.model.dart';

class ExtendSelectionOrCaretPositionAction extends ContextAction<
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent> {
  late final EditorService _editorService;

  final EditorState state;
  final TextBoundaryM Function(
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent intent,
  ) getTextBoundariesForIntent;

  ExtendSelectionOrCaretPositionAction(
    this.getTextBoundariesForIntent,
    this.state,
  ) {
    _editorService = EditorService(state);
  }

  @override
  Object? invoke(
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent intent, [
    BuildContext? context,
  ]) {
    final selection = _editorService.plainText.selection;

    assert(selection.isValid);

    final textBoundary = getTextBoundariesForIntent(intent);
    final textBoundarySelection = textBoundary.plainText.selection;

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
        textBoundary.plainText,
        newSelection,
        SelectionChangedCause.keyboard,
      ),
    );
  }

  @override
  bool get isActionEnabled =>
      state.config.enableInteractiveSelection &&
      _editorService.plainText.selection.isValid;
}
