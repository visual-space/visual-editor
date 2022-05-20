# Highlights
Renders temporary text markers sensitive to taps. Highlights can be added and removed at runtime. They do not change the underlying document in any shape or form. The highlights are simply rendered on top of the text. Highlights are sensitive to taps and hovers. Custom colors can be defined. 

## Data Model
**highlight.model.dart**
```dart
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

```

## Usage Instructions
**sample-highlights.const.dart**
```dart
import 'package:flutter/material.dart';
import 'package:visual_editor/visual-editor.dart';

final SAMPLE_HIGHLIGHTS = [
  HighlightM(
      textSelection: const TextSelection(
        baseOffset: 210,
        extentOffset: 240,
      ),
      onEnter: (_) {
        print('Entering highlight 1');
      },
      onLeave: (_) {
        print('Leaving highlight 1');
      },
      onSingleTapUp: (_) {
        print('Tapped highlight 1');
      }
  ),
];
```

Create a new controller and provide the highlights you desire.
```dart
final _controller = QuillController(
  document: doc,
  selection: const TextSelection.collapsed(offset: 0),
  highlights: SAMPLE_HIGHLIGHTS,
);
```

## Storing Highlights in The Delta Document
We did not implement a custom attribute to store the ids of the highlights. We leave this choice to the client developer. The delta text format can be extended with arbitrary attributes. Use whatever attribute works for you and parse the delta documents to extract teh highlights before providing it to the the EditorController. Thought this could be subject to change depending on the initial feedback.

**Example**
```json
[
  {
    "insert": "Flutter Quill"
  },
  {
    "attributes": {
      "header": 1
    },
    "insert": "\n",
    "highlightId": "uuid"
  }
]
```