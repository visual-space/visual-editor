import 'package:flutter/material.dart';

import '../../../flutter_quill.dart';

const _DEFAULT_HIGHLIGHT_COLOR = Color.fromRGBO(0xFF, 0xC1, 0x17, .3);
const _HOVERED_HIGHLIGHT_COLOR = Color.fromRGBO(0xFF, 0xC1, 0x17, .5);

/// Highlights can be provided to the [QuillController].
/// The highlights are dynamic and can be changed at runtime.
/// If you need static highlights you can use the foreground color option.
/// Highlights can be hovered.
/// Callbacks can be defined to react to hovering and tapping.
@immutable
class Highlight {
  final TextSelection textSelection;
  final Color color;
  final Color hoverColor;
  final Function(Highlight highlight)? onSingleTapUp;
  final Function(Highlight highlight)? onEnter;
  final Function(Highlight highlight)? onHover;
  final Function(Highlight highlight)? onLeave;

  const Highlight({
    required this.textSelection,
    this.color = _DEFAULT_HIGHLIGHT_COLOR,
    this.hoverColor = _HOVERED_HIGHLIGHT_COLOR,
    this.onSingleTapUp,
    this.onEnter,
    this.onHover,
    this.onLeave,
  });
}
