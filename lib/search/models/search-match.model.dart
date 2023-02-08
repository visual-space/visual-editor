import 'package:flutter/material.dart';

// Matches found in a document when a users use search bar.
// We need text selection because every match will be highlighted
// The information about the position is needed for features like matches positions slimbar
// and navigate trough matches (will be added in the feature)
@immutable
class SearchMatchM {
  final TextSelection textSelection;
  final List<TextBox>? rectangles;
  final Offset? docRelPosition;

  SearchMatchM({
    required this.textSelection,
    this.rectangles,
    this.docRelPosition,
  });

  @override
  String toString() {
    return 'SearchMatchM('
        'rectangles: $rectangles,'
        'docRelPosition: $docRelPosition,'
        'textSelection: $textSelection,'
        ')';
  }

  SearchMatchM copyWith({
    List<TextBox>? rectangles,
    Offset? docRelPosition,
    TextSelection? textSelection,
  }) =>
      SearchMatchM(
        rectangles: rectangles ?? this.rectangles,
        docRelPosition: docRelPosition ?? this.docRelPosition,
        textSelection: textSelection ?? this.textSelection,
      );
}
