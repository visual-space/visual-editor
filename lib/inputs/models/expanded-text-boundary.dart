import 'package:flutter/material.dart';

import 'base/text-boundary.model.dart';

// Expands the innerTextBoundary with outerTextBoundary.
class ExpandedTextBoundary extends TextBoundaryM {
  ExpandedTextBoundary(
    this.innerTextBoundary,
    this.outerTextBoundary,
  );

  final TextBoundaryM innerTextBoundary;
  final TextBoundaryM outerTextBoundary;

  @override
  TextEditingValue get plainText {
    assert(innerTextBoundary.plainText ==
        outerTextBoundary.plainText);

    return innerTextBoundary.plainText;
  }

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) =>
      outerTextBoundary.getLeadingTextBoundaryAt(
        innerTextBoundary.getLeadingTextBoundaryAt(position),
      );

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) =>
      outerTextBoundary.getTrailingTextBoundaryAt(
        innerTextBoundary.getTrailingTextBoundaryAt(position),
      );
}
