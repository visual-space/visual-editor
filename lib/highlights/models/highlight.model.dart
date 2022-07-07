import 'package:flutter/material.dart';

const _DEFAULT_HIGHLIGHT_COLOR = Color.fromRGBO(0xFF, 0xC1, 0x17, .3);
const _HOVERED_HIGHLIGHT_COLOR = Color.fromRGBO(0xFF, 0xC1, 0x17, .5);

// Highlights can be provided to the EditorController.
// The highlights are dynamic and can be changed at runtime.
// If you need static highlights you can use the foreground color option.
// Callbacks can be defined to react to hovering and tapping.
@immutable
class HighlightM {
  final TextSelection textSelection;
  final Color color;
  final Color hoverColor;
  final Function(HighlightM highlight)? onSingleTapUp;
  final Function(HighlightM highlight)? onEnter;
  final Function(HighlightM highlight)? onHover;
  final Function(HighlightM highlight)? onLeave;

  const HighlightM({
    required this.textSelection,
    this.color = _DEFAULT_HIGHLIGHT_COLOR,
    this.hoverColor = _HOVERED_HIGHLIGHT_COLOR,
    this.onSingleTapUp,
    this.onEnter,
    this.onHover,
    this.onLeave,
  });
}
