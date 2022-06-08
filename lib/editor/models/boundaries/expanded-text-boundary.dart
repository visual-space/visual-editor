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
  TextEditingValue get textEditingValue {
    assert(innerTextBoundary.textEditingValue ==
        outerTextBoundary.textEditingValue);
    return innerTextBoundary.textEditingValue;
  }

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    return outerTextBoundary.getLeadingTextBoundaryAt(
      innerTextBoundary.getLeadingTextBoundaryAt(position),
    );
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return outerTextBoundary.getTrailingTextBoundaryAt(
      innerTextBoundary.getTrailingTextBoundaryAt(position),
    );
  }
}
