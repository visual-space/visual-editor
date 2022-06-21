import 'package:flutter/material.dart';

import '../../controller/services/editor-text.service.dart';
import '../../editor/models/boundaries/character-boundary.model.dart';
import '../../editor/state/editor-config.state.dart';
import '../models/base/text-boundary.model.dart';

class DeleteTextAction<T extends DirectionalTextEditingIntent>
    extends ContextAction<T> {
  final _editorTextService = EditorTextService();
  final _editorConfigState = EditorConfigState();

  final TextBoundaryM Function(T intent) getTextBoundariesForIntent;

  DeleteTextAction(
    this.getTextBoundariesForIntent,
  );

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    final selection = _editorTextService.textEditingValue.selection;

    assert(selection.isValid);

    if (!selection.isCollapsed) {
      return Actions.invoke(
        context!,
        ReplaceTextIntent(
          _editorTextService.textEditingValue,
          '',
          _expandNonCollapsedRange(),
          SelectionChangedCause.keyboard,
        ),
      );
    }

    final textBoundary = getTextBoundariesForIntent(intent);

    if (!textBoundary.textEditingValue.selection.isValid) {
      return null;
    }

    if (!textBoundary.textEditingValue.selection.isCollapsed) {
      return Actions.invoke(
        context!,
        ReplaceTextIntent(
          _editorTextService.textEditingValue,
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
      !_editorConfigState.config.readOnly &&
      _editorTextService.textEditingValue.selection.isValid;

  // === PRIVATE ===

  TextRange _expandNonCollapsedRange() {
    final TextRange selection = _editorTextService.textEditingValue.selection;

    assert(selection.isValid);
    assert(!selection.isCollapsed);

    final TextBoundaryM atomicBoundary = CharacterBoundary();

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
