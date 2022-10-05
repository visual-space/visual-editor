import 'package:flutter/material.dart';

// Used to output the rectangles of various text selections
// Ex: Highlights overlap multiple lines, therefore we need to extract multiple sets of markers 
// from multiple lines and multiple styling fragments for one highlight.
@immutable
class SelectionRectanglesM {
  final TextSelection textSelection;

  // At initialisation the editor will parse the delta document and will start rendering the text lines one by one.
  // The rectangles and the relative position of the text line are useful for
  // rendering text attachments after the editor build is completed.
  // (!) Added at runtime
  final List<TextBox> rectangles;

  // Global position relative to the viewport of the EditableTextLine that contains the text selection.
  // We don't expose the full TextLine to avoid access from the public scope to the private scope.
  // (!) Added at runtime
  final Offset docRelPosition;

  const SelectionRectanglesM({
    this.textSelection = const TextSelection(
      baseOffset: 0,
      extentOffset: 0,
    ),
    this.rectangles = const [],
    this.docRelPosition = Offset.zero,
  });

  @override
  String toString() {
    return 'SelectionRectanglesM('
        'textSelection: $textSelection,'
        'rectangles: $rectangles,'
        'docRelPosition: $docRelPosition,'
        ')';
  }

  SelectionRectanglesM copyWith({
    TextSelection? textSelection,
    List<TextBox>? rectangles,
    Offset? docRelPosition,
  }) =>
      SelectionRectanglesM(
        textSelection: textSelection ?? this.textSelection,
        rectangles: rectangles ?? this.rectangles,
        docRelPosition: docRelPosition ?? this.docRelPosition,
      );
}
