import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../inputs/models/base/text-boundary.model.dart';
import '../../../shared/state/editor.state.dart';
import '../../services/editor.service.dart';

// Most apps delete the entire grapheme when the backspace key is pressed.
// Also always put the new caret location to character boundaries to avoid
// sending malformed UTF-16 code units to the paragraph builder.
// TODO Review, this is not a model
class CharacterBoundary extends TextBoundaryM {
  late final EditorService _editorService;

  CharacterBoundary(EditorState state) {
    _editorService = EditorService(state);

    plainText = _editorService.plainText;
  }

  @override
  late TextEditingValue plainText;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    final int endOffset = math.min(
      position.offset + 1,
      plainText.text.length,
    );

    return TextPosition(
      offset: CharacterRange.at(
        plainText.text,
        position.offset,
        endOffset,
      ).stringBeforeLength,
    );
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    final int endOffset = math.min(
      position.offset + 1,
      plainText.text.length,
    );

    final range = CharacterRange.at(
      plainText.text,
      position.offset,
      endOffset,
    );

    return TextPosition(
      offset: plainText.text.length - range.stringAfterLength,
    );
  }

  @override
  TextRange getTextBoundaryAt(TextPosition position) {
    final int endOffset = math.min(
      position.offset + 1,
      plainText.text.length,
    );

    final range = CharacterRange.at(
      plainText.text,
      position.offset,
      endOffset,
    );

    return TextRange(
      start: range.stringBeforeLength,
      end: plainText.text.length - range.stringAfterLength,
    );
  }
}
