import 'package:flutter/material.dart';
import 'vertical-spacing.model.dart';

// Style theme applied to a block of rich text, including single-line paragraphs.
class TextBlockStyleM {
  // Base text style for a text block.
  final TextStyle style;

  final VerticalSpacing verticalSpacing;
  final VerticalSpacing lineSpacing;

  // Decoration of a text block.
  // If present, is painted in the blocks area, excluding any [spacing].
  final BoxDecoration? decoration;

  TextBlockStyleM(
    this.style,
    this.verticalSpacing,
    this.lineSpacing,
    this.decoration,
  );
}
