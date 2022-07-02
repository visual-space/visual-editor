import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../inputs/models/base/text-boundary.model.dart';
import '../../../shared/state/editor.state.dart';

// Most apps delete the entire grapheme when the backspace key is pressed.
// Also always put the new caret location to character boundaries to avoid
// sending malformed UTF-16 code units to the paragraph builder.
class CharacterBoundary extends TextBoundaryM {
  CharacterBoundary(EditorState state) {
    textEditingValue = state.refs.editorController.plainTextEditingValue;
  }

  @override
  late TextEditingValue textEditingValue;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    final int endOffset = math.min(
      position.offset + 1,
      textEditingValue.text.length,
    );

    return TextPosition(
      offset:
          CharacterRange.at(textEditingValue.text, position.offset, endOffset)
              .stringBeforeLength,
    );
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    final int endOffset = math.min(
      position.offset + 1,
      textEditingValue.text.length,
    );

    final range = CharacterRange.at(
      textEditingValue.text,
      position.offset,
      endOffset,
    );

    return TextPosition(
      offset: textEditingValue.text.length - range.stringAfterLength,
    );
  }

  @override
  TextRange getTextBoundaryAt(TextPosition position) {
    final int endOffset = math.min(
      position.offset + 1,
      textEditingValue.text.length,
    );

    final range = CharacterRange.at(
      textEditingValue.text,
      position.offset,
      endOffset,
    );

    return TextRange(
      start: range.stringBeforeLength,
      end: textEditingValue.text.length - range.stringAfterLength,
    );
  }
}
