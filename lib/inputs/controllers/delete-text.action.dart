import 'package:flutter/material.dart';

import '../../editor/models/boundaries/character-boundary.model.dart';
import '../../shared/state/editor.state.dart';
import '../models/base/text-boundary.model.dart';

class DeleteTextAction<T extends DirectionalTextEditingIntent>
    extends ContextAction<T> {
  final EditorState state;
  final TextBoundaryM Function(
    T intent,
    EditorState state,
  ) getTextBoundariesForIntent;

  DeleteTextAction(
    this.getTextBoundariesForIntent,
    this.state,
  );

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    final selection =
        state.refs.editorController.plainTextEditingValue.selection;

    assert(selection.isValid);

    if (!selection.isCollapsed) {
      return Actions.invoke(
        context!,
        ReplaceTextIntent(
          state.refs.editorController.plainTextEditingValue,
          '',
          _expandNonCollapsedRange(),
          SelectionChangedCause.keyboard,
        ),
      );
    }

    final textBoundary = getTextBoundariesForIntent(intent, state);

    if (!textBoundary.textEditingValue.selection.isValid) {
      return null;
    }

    if (!textBoundary.textEditingValue.selection.isCollapsed) {
      return Actions.invoke(
        context!,
        ReplaceTextIntent(
          state.refs.editorController.plainTextEditingValue,
          '',
          _expandNonCollapsedRange(),
          SelectionChangedCause.keyboard,
        ),
      );
    }

    return Actions.invoke(
      context!,
      ReplaceTextIntent(
        textBoundary.textEditingValue,
        '',
        textBoundary.getTextBoundaryAt(
          textBoundary.textEditingValue.selection.base,
        ),
        SelectionChangedCause.keyboard,
      ),
    );
  }

  @override
  bool get isActionEnabled =>
      !state.editorConfig.config.readOnly &&
      state.refs.editorController.plainTextEditingValue.selection.isValid;

  // === PRIVATE ===

  TextRange _expandNonCollapsedRange() {
    final TextRange selection =
        state.refs.editorController.plainTextEditingValue.selection;

    assert(selection.isValid);
    assert(!selection.isCollapsed);

    final TextBoundaryM atomicBoundary = CharacterBoundary(state);

    return TextRange(
      start: atomicBoundary
          .getLeadingTextBoundaryAt(
            TextPosition(offset: selection.start),
          )
          .offset,
      end: atomicBoundary
          .getTrailingTextBoundaryAt(
            TextPosition(offset: selection.end - 1),
          )
          .offset,
    );
  }
}
