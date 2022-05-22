import 'package:flutter/material.dart';

// Configures the style of the cursor for a VisualEditor widget.
@immutable
class CursorStyleCfgM {
  final Color cursorColor;
  final Radius? cursorRadius;
  final Offset? cursorOffset;
  final bool paintCursorAboveText;
  final bool cursorOpacityAnimates;

  const CursorStyleCfgM({
    required this.cursorColor,
    this.cursorRadius,
    this.cursorOffset,
    required this.paintCursorAboveText,
    required this.cursorOpacityAnimates,
  });
}
