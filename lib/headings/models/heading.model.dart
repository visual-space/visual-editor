import 'package:flutter/material.dart';

// Used to extract all headings of a document
// For every heading we need the text and the position of
// the heading in the document (to be used later for custom features)
class HeadingM {
  final String? text;
  final Offset? docRelPosition;
  final List<TextBox>? rectangles;

  const HeadingM({
    this.text,
    this.docRelPosition,
    this.rectangles,
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
        ')';
  }

  HeadingM copyWith({
    String? text,
    Offset? docRelPosition,
    List<TextBox>? rectangles,
  }) =>
      HeadingM(
        text: text ?? this.text,
        docRelPosition: docRelPosition ?? this.docRelPosition,
        rectangles: rectangles ?? this.rectangles,
      );
}
