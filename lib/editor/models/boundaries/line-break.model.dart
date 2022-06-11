import 'package:flutter/services.dart';

import 'base/text-boundary.model.dart';

// The linebreaks of the current text layout.
// The input [TextPosition]s are interpreted as caret locations because [TextPainter.getLineAtOffset] is text-affinity-aware.
class LineBreak extends TextBoundaryM {
  const LineBreak(
    this.textLayout,
    this.textEditingValue,
  );

  final TextLayoutMetrics textLayout;

  @override
  final TextEditingValue textEditingValue;

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
