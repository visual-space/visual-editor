import 'package:flutter/material.dart';
import '../../../doc-tree/models/vertical-spacing.model.dart';

// Style theme applied to a block of rich text, including single-line paragraphs.
class TextBlockStyleM {
  // Base text style for a text block.
  final TextStyle style;

  final VerticalSpacing verticalSpacing;
  final VerticalSpacing lineSpacing;

  // Decoration of a text block.
  // If present, is painted in the doc-tree area, excluding any [spacing].
  final BoxDecoration? decoration;

  const TextBlockStyleM(
    this.style,
    this.verticalSpacing,
    this.lineSpacing,
    this.decoration,
  );
}
