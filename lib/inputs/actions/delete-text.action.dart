import 'package:flutter/material.dart';

import '../../editor/models/boundaries/character-boundary.model.dart';
import '../../editor/services/editor.service.dart';
import '../../shared/state/editor.state.dart';
import '../models/base/text-boundary.model.dart';

class DeleteTextAction<T extends DirectionalTextEditingIntent>
    extends ContextAction<T> {
  late final EditorService _editorService;

  final EditorState state;
  final TextBoundaryM Function(T intent) getTextBoundariesForIntent;

  DeleteTextAction(
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

    if (!selection.isCollapsed) {
      return Actions.invoke(
        context!,
        ReplaceTextIntent(
          plainText,
          '',
          _expandNonCollapsedRange(),
          SelectionChangedCause.keyboard,
        ),
      );
    }

    final textBoundary = getTextBoundariesForIntent(intent);

    if (!textBoundary.plainText.selection.isValid) {
      return null;
    }

    if (!textBoundary.plainText.selection.isCollapsed) {
      return Actions.invoke(
        context!,
        ReplaceTextIntent(
          plainText,
          '',
          _expandNonCollapsedRange(),
          SelectionChangedCause.keyboard,
        ),
      );
    }

    return Actions.invoke(
      context!,
      ReplaceTextIntent(
        textBoundary.plainText,
        '',
        textBoundary.getTextBoundaryAt(
          textBoundary.plainText.selection.base,
        ),
        SelectionChangedCause.keyboard,
      ),
    );
  }

  @override
  bool get isActionEnabled {
    final plainText = _editorService.plainText;
    return !state.config.readOnly && plainText.selection.isValid;
  }

  // === PRIVATE ===

  TextRange _expandNonCollapsedRange() {
    final TextRange selection = _editorService.plainText.selection;

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
