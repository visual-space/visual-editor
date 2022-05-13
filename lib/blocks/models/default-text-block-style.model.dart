import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

/// Style theme applied to a block of rich text, including single-line paragraphs.
class DefaultTextBlockStyle {
  DefaultTextBlockStyle(
    this.style,
    this.verticalSpacing,
    this.lineSpacing,
    this.decoration,
  );

  /// Base text style for a text block.
  final TextStyle style;

  /// Vertical spacing around a text block.
  final Tuple2<double, double> verticalSpacing;

  /// Vertical spacing for individual lines within a text block.
  ///
  final Tuple2<double, double> lineSpacing;

  /// Decoration of a text block.
  ///
  /// Decoration, if present, is painted in the blocks area, excluding
  /// any [spacing].
  final BoxDecoration? decoration;
}
