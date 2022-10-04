# Highlights
Renders temporary text markers sensitive to taps. Highlights can be added and removed at runtime. They do not change the underlying document in any shape or form. The highlights are simply rendered on top of the text. Highlights are sensitive to taps and hovers. Custom colors can be defined. 

## Data Model
**highlight.model.dart**
```dart
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
import 'package:visual_editor/visual_editor.dart';

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
final _controller = EditorController(
  document: doc,
  highlights: SAMPLE_HIGHLIGHTS,
);
```

## Adding Highlights From The Controller
Checkout the highlights demo page for a full sample.

```dart
_controller?.addHighlight(
  HighlightM(
    textSelection: _selection.copyWith(),
    onEnter: (_) {},
    onLeave: (_) {},
    onSingleTapUp: (_) {},
  ),
);
```

Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.