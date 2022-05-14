import 'package:flutter/material.dart';

// TODO Review if this needs to be focused on theming only or can be merged with other concerns.
class EditorIconThemeM {
  final Color? iconSelectedColor;
  final Color? iconUnselectedColor;
  final Color? iconSelectedFillColor;
  final Color? iconUnselectedFillColor;
  final Color? disabledIconColor;
  final Color? disabledIconFillColor;
  final double? borderRadius;

  const EditorIconThemeM({
    this.iconSelectedColor,
    this.iconUnselectedColor,
    this.iconSelectedFillColor,
    this.iconUnselectedFillColor,
    this.disabledIconColor,
    this.disabledIconFillColor,
    this.borderRadius,
  });
}
