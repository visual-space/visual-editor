import 'package:flutter/material.dart';
import '../../../doc-tree/models/vertical-spacing.model.dart';

// Style theme applied to a block of rich text, including single-line paragraphs.
class TextBlockStyleM {
  // Base text style for a text block.
  final TextStyle style;

  final VerticalSpacing verticalSpacing;
  final VerticalSpacing lineSpacing;

  // Set a different value for the last line spacing in a block.
  // Having same spacing for all lines could led to undesired spacing at the end of a block.
  final VerticalSpacing lastLineSpacing;

  // Decoration of a text block.
  // If present, is painted in the doc-tree area, excluding any [spacing].
  final BoxDecoration? decoration;

  const TextBlockStyleM(
    this.style,
    this.verticalSpacing,
    this.lineSpacing,
    this.lastLineSpacing,
    this.decoration,
  );
}
