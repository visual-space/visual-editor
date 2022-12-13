import 'package:flutter/material.dart';

// Used to extract all headings of a document
// For every heading we need the text, the position of
// the heading in the document, including the text selection, and rectangles
// (to be used later for custom features)
class HeadingM {
  final String? text;
  final Offset? docRelPosition;
  final List<TextBox>? rectangles;
  final TextSelection? selection;

  const HeadingM({
    this.text,
    this.docRelPosition,
    this.rectangles,
    this.selection,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
      };

  @override
  String toString() {
    return 'HeadingM('
        'text: $text, '
        'rectangles: $rectangles,'
        'docRelPosition: $docRelPosition,'
        'selection: $selection,'
        ')';
  }

  HeadingM copyWith({
    String? text,
    Offset? docRelPosition,
    List<TextBox>? rectangles,
    TextSelection? selection,
  }) =>
      HeadingM(
        text: text ?? this.text,
        docRelPosition: docRelPosition ?? this.docRelPosition,
        rectangles: rectangles ?? this.rectangles,
        selection: selection ?? this.selection,
      );
}
