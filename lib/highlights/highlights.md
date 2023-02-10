# Highlights
Renders temporary text markers sensitive to taps. Highlights can be added and removed at runtime. They do not change the underlying document in any shape or form. The highlights are simply rendered on top of the text. Highlights are sensitive to taps and hovers. Custom colors can be defined.

## Architecture
In Flutter we don't have any built in mechanic for easily detecting hover over random stretches of text. Therefore we have to write our own code for detecting hovering over highlights. When the editor is initialised we store all the highlights in the state store. Once the build() method is executed we have references to all the rendering classes for every single class. Using a callback after build we query every single line to check if it has highlights,and if so we request the rectangles needed to draw the highlights. Since one highlights can contain multiple lines we group the markers in batches. For each line we cache also the local to global offset. This offset will be essential to align the pointer coordinates with the highlights rectangles coordinates. Once we have the rectangles we cache them by deep cloning the highlights to include this information.

When the user pointer enters the editor screen space then the TextGestures widget matches the correct action (onHover). In the on hover method we check every single highlight to see if any of the rectangles are intersected by the pointer. Once one or many highlights are matched we then cache the ids. On every single hover event we compare if new ids have been added or removed. For each added or removed highlight we run the corresponding callbacks. Then we cache the new hovered highlights in the state store and trigger a new editor build (layout update). When the editor is running the build cycle each line will check again for highlights that it has to draw and will apply the hovering color according to the hovered highlights from the state stare.  Note that we are using `ignoreFocusOnTextChange` to avoid triggering the caret when new builds are triggered via the hovering feature.


## Data Model
**highlight.model.dart**
```dart
@immutable
class HighlightM {
  final String id;
  final TextSelection textSelection;
  final Color color;
  final Color hoverColor;
  final Function(HighlightM highlight)? onSingleTapUp;
  final Function(HighlightM highlight)? onEnter;
  final Function(HighlightM highlight)? onHover;
  final Function(HighlightM highlight)? onExit;

  const HighlightM({
    required this.id,
    required this.textSelection,
    this.color = _DEFAULT_HIGHLIGHT_COLOR,
    this.hoverColor = _HOVERED_HIGHLIGHT_COLOR,
    this.onSingleTapUp,
    this.onEnter,
    this.onHover,
    this.onExit,
  });
}
```

## Usage Instructions
**sample-highlights.const.dart**
```dart
import 'package:flutter/material.dart';
import 'package:visual_editor/visual_editor.dart';

final DEMO_HIGHLIGHTS = [
  HighlightM(
    id: 'flsnLKJH83',
    textSelection: const TextSelection(
      baseOffset: 210,
      extentOffset: 240,
    ),
    onEnter: (highlight) {
      print('Entering highlight 1');
    },
    onExit: (highlight) {
      print('Leaving highlight 1');
    },
    onSingleTapUp: (highlight) {
      print('Tapped highlight 1');
    }
  ),
];
```

Create a new editor and controller pair and then provide the highlights you desire.

```dart
final _controller = EditorController(
  document: doc,
);
```
```dart
Widget _editor() => VisualEditor(
  controller: _controller,
  config: EditorConfigM(
    highlights: DEMO_HIGHLIGHTS,
  ),
);
```

## Adding Highlights From The Controller
Checkout the highlights demo page for a full sample.

```dart
_controller?.addHighlight(
  HighlightM(
    id: getTimeBasedId(), // Use proper UUIDs
    textSelection: _selection.copyWith(),
    onEnter: (highlight) {},
    onExit: (highlight) {},
    onSingleTapUp: (highlight) {},
  ),
);
```

## Displaying A Custom Widget When Tapping A Highlight

This is a general overview of setting up a marker menu or custom widgets when the marker is tapped. To view a complete sample go to the `SelectionMenuPage` and inspect the code.

```dart
Widget build(BuildContext context) => Stack(
  children: [
    DemoPageScaffold(
      child: _controller != null
          ? _col(
        children: [
          _editor(),
          _toolbar(),
        ],
      )
          : Loading(),
    ),

    // Has to be a Positioned Widget (anything you need)
    if (_isQuickMenuVisible) _quickMenu(),
  ],
);
```

Init the editor with callbacks defined for the highlights.

```dart
Widget _editor() => VisualEditor(
  controller: _controller,
  config: EditorConfigM(
    onScroll: _updateQuickMenuPosition,
    
    // Hide menu while the selection is changing
    onSelectionChanged: (selection, rectangles) {
      _hideQuickMenu();
    },

    highlights: [
      HighlightM(
        id: '1255915688987000',
        textSelection: const TextSelection(
          baseOffset: 30,
          extentOffset: 40,
        ),
        
        // Use your own logic for rendering and positioning the attached widget(s)
        onSingleTapUp: _displayQuickMenuOnHighlight,
      )
    ],
  ),
);
```

