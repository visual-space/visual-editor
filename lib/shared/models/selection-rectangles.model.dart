import 'package:flutter/material.dart';

import '../../document/models/material/offset.model.dart';
import '../../document/models/material/test-selection.model.dart';
import '../../document/models/material/text-box.model.dart';

// Used to output the rectangles of various text selections
// Ex: Highlights overlap multiple lines, therefore we need to extract multiple sets of markers
// from multiple lines and multiple styling fragments for one highlight.
@immutable
class SelectionRectanglesM {
  final TextSelectionM textSelection;

  // At initialisation the editor will parse the delta document and will start rendering the text lines one by one.
  // The rectangles and the relative position of the text line are useful for
  // rendering text attachments after the editor build is completed.
  // (!) Added at runtime
  final List<TextBoxM> rectangles;

  // Global position relative to the viewport of the EditableTextLine that contains the text selection.
  // We don't expose the full TextLine to avoid access from the public scope to the private scope.
  // (!) Added at runtime
  final OffsetM docRelPosition;

  const SelectionRectanglesM({
    this.textSelection = const TextSelectionM(
      baseOffset: 0,
      extentOffset: 0,
    ),
    this.rectangles = const [],
    this.docRelPosition = OffsetM.zero,
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
    TextSelectionM? textSelection,
    List<TextBoxM>? rectangles,
    OffsetM? docRelPosition,
  }) =>
      SelectionRectanglesM(
        textSelection: textSelection ?? this.textSelection,
        rectangles: rectangles ?? this.rectangles,
        docRelPosition: docRelPosition ?? this.docRelPosition,
      );
}
