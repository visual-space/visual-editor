import 'package:flutter/services.dart';

import 'base/text-boundary.model.dart';

// The word modifier generally removes the word boundaries around white spaces
// (and newlines), IOW white spaces and some other punctuations are considered
// a part of the next word in the search direction.
class WhitespaceBoundary extends TextBoundaryM {
  const WhitespaceBoundary(
    this.plainText,
  );

  @override
  final TextEditingValue plainText;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    for (var index = position.offset; index >= 0; index -= 1) {
      if (!TextLayoutMetrics.isWhitespace(
          plainText.text.codeUnitAt(index))) {
        return TextPosition(offset: index);
      }
    }

    return const TextPosition(offset: 0);
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    for (var index = position.offset;
        index < plainText.text.length;
        index += 1) {
      if (!TextLayoutMetrics.isWhitespace(
        plainText.text.codeUnitAt(index),
      )) {
        return TextPosition(offset: index + 1);
      }
    }

    return TextPosition(offset: plainText.text.length);
  }
}
