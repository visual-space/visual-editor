import 'package:flutter/services.dart';

import 'base/text-boundary.model.dart';

// The linebreaks of the current text layout.
// The input TextPositions are interpreted as caret locations because
// TextPainter.getLineAtOffset is text-affinity-aware.
class LineBreak extends TextBoundaryM {
  const LineBreak(
    this.textLayout,
    this.plainText,
  );

  final TextLayoutMetrics textLayout;

  @override
  final TextEditingValue plainText;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: textLayout.getLineAtOffset(position).start,
    );
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: textLayout.getLineAtOffset(position).end,
      affinity: TextAffinity.upstream,
    );
  }
}
