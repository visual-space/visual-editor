import 'package:flutter/material.dart';

import 'base/text-boundary.model.dart';

// A TextBoundaryM that creates a [TextRange] where its start is from the specified leading text boundary
// and its end is from the specified trailing text boundary.
class MixedBoundary extends TextBoundaryM {
  MixedBoundary(
    this.leadingTextBoundary,
    this.trailingTextBoundary,
  );

  final TextBoundaryM leadingTextBoundary;
  final TextBoundaryM trailingTextBoundary;

  @override
  TextEditingValue get textEditingValue {
    assert(leadingTextBoundary.textEditingValue ==
        trailingTextBoundary.textEditingValue);
    return leadingTextBoundary.textEditingValue;
  }

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) =>
      leadingTextBoundary.getLeadingTextBoundaryAt(position);

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) =>
      trailingTextBoundary.getTrailingTextBoundaryAt(position);
}
