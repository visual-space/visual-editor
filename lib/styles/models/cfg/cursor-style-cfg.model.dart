import 'package:flutter/material.dart';

// Configures the style of the cursor for a VisualEditor widget.
@immutable
class CursorStyleCfgM {
  final Color cursorColor;
  final bool paintCursorAboveText;
  final bool cursorOpacityAnimates;
  final Radius? cursorRadius;
  final Offset? cursorOffset;

  const CursorStyleCfgM({
    required this.cursorColor,
    required this.paintCursorAboveText,
    required this.cursorOpacityAnimates,
    this.cursorRadius,
    this.cursorOffset,
  });
}
