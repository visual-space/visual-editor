import 'package:flutter/services.dart';

import 'base/text-boundary.model.dart';

// [UAX #29](https://unicode.org/reports/tr29/) defined word boundaries.
// TODO Review why we collide with WordBoundary from Flutter
// I used VE suffix to differentiate
class WordBoundaryVE extends TextBoundaryM {
  const WordBoundaryVE(
    this.textLayout,
    this.plainText,
  );

  final TextLayoutMetrics textLayout;

  @override
  final TextEditingValue plainText;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: textLayout.getWordBoundary(position).start,
      // Word boundary seems to always report downstream on many platforms.
      // ignore: avoid_redundant_argument_values
      affinity: TextAffinity.downstream,
    );
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: textLayout.getWordBoundary(position).end,
      // Word boundary seems to always report downstream on many platforms.
      // ignore: avoid_redundant_argument_values
      affinity: TextAffinity.downstream,
    );
  }
}
