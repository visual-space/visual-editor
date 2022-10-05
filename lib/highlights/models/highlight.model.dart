import 'package:flutter/material.dart';

import '../../shared/models/selection-rectangles.model.dart';

// TODO Collect all the visual defaults in one file
const _DEFAULT_HIGHLIGHT_COLOR = Color.fromRGBO(0xFF, 0xC1, 0x17, .3);
const _HOVERED_HIGHLIGHT_COLOR = Color.fromRGBO(0xFF, 0xC1, 0x17, .5);

// Highlights can be provided to the EditorController.
// The highlights are dynamic and can be changed at runtime.
// If you need static highlights you can use the foreground color option.
// Callbacks can be defined to react to hovering and tapping.
// TODO Consider adding support for tap down
@immutable
class HighlightM {
  // If we are using a pure functional approach in our code we can no longer
  // rely on references to search for highlights in the state store.
  // We need ids to be able to track which highlights are hovered.
  final String id;
  final TextSelection textSelection;
  final Color color;
  final Color hoverColor;
  final Function(HighlightM highlight)? onSingleTapUp;
  final Function(HighlightM highlight)? onEnter;
  final Function(HighlightM highlight)? onHover;
  final Function(HighlightM highlight)? onExit;

  // At initialisation the editor will parse the delta document and will start rendering the text lines one by one.
  // Each EditableTextLine renders the highlights overlapping that particular LineM.
  // When drawing each highlight we retrieve the rectangles and the relative position of the text line.
  // Each batch of rectangles for each each line has a distinct docRelPosition.
  // This information is essential for rendering highlight attachments after the editor build is completed.
  // (!) Added at runtime
  final List<SelectionRectanglesM>? rectanglesByLines;

  const HighlightM({
    required this.id,
    required this.textSelection,
    this.color = _DEFAULT_HIGHLIGHT_COLOR,
    this.hoverColor = _HOVERED_HIGHLIGHT_COLOR,
    this.onSingleTapUp,
    this.onEnter,
    this.onHover,
    this.onExit,
    this.rectanglesByLines,
  });

  @override
  String toString() {
    return 'HighlightM('
        'id: $id, '
        'textSelection: $textSelection, '
        'color: $color, '
        'rectanglesByLines: $rectanglesByLines,'
        ')';
  }

  HighlightM copyWith({
    String? id,
    TextSelection? textSelection,
    Color? color,
    Color? hoverColor,
    Function(HighlightM highlight)? onSingleTapUp,
    Function(HighlightM highlight)? onEnter,
    Function(HighlightM highlight)? onHover,
    Function(HighlightM highlight)? onExit,
    List<SelectionRectanglesM>? rectanglesByLines,
    Offset? docRelPosition,
  }) =>
      HighlightM(
        id: id ?? this.id,
        textSelection: textSelection ?? this.textSelection,
        color: color ?? this.color,
        hoverColor: hoverColor ?? this.hoverColor,
        onSingleTapUp: onSingleTapUp ?? this.onSingleTapUp,
        onEnter: onEnter ?? this.onEnter,
        onHover: onHover ?? this.onHover,
        onExit: onExit ?? this.onExit,
        rectanglesByLines: rectanglesByLines ?? this.rectanglesByLines,
      );
}
