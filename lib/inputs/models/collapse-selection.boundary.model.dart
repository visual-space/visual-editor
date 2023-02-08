import 'package:flutter/material.dart';

import 'base/text-boundary.model.dart';

// Force the innerTextBoundary to interpret the input [TextPosition]s as caret locations instead of code unit positions.
// The innerTextBoundary must be a [TextBoundaryM] that interprets the input [TextPosition]s as code unit positions.
class CollapsedSelectionBoundary extends TextBoundaryM {
  CollapsedSelectionBoundary(
    this.innerTextBoundary,
    this.isForward,
  );

  final TextBoundaryM innerTextBoundary;
  final bool isForward;

  @override
  TextEditingValue get plainText => innerTextBoundary.plainText;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    return isForward
        ? innerTextBoundary.getLeadingTextBoundaryAt(position)
        : position.offset <= 0
            ? const TextPosition(offset: 0)
            : innerTextBoundary.getLeadingTextBoundaryAt(
                TextPosition(offset: position.offset - 1));
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return isForward
        ? innerTextBoundary.getTrailingTextBoundaryAt(position)
        : position.offset <= 0
            ? const TextPosition(offset: 0)
            : innerTextBoundary.getTrailingTextBoundaryAt(
                TextPosition(offset: position.offset - 1));
  }
}
