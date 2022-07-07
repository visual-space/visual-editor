# Markers
Renders permanent text markers sensitive to taps. Markers are defined in the delta document. Unlike markers, markers change the delta document by adding attributes. The markers are rendered on top of the text. Markers are sensitive to taps and hovers. Custom marker types with custom colors and behaviours can be defined. 

## Data Model
**marker-type.model.dart**
```dart
@immutable
class MarkerTypeM {
  final String id;
  final String name;
  final Color color;
  final Color hoverColor;
  final Function(MarkersTypeM marker)? onSingleTapUp;
  final Function(MarkersTypeM marker)? onEnter;
  final Function(MarkersTypeM marker)? onHover;
  final Function(MarkersTypeM marker)? onLeave;

  const MarkerTypeM({
    required this.id,
    required this.name,
    this.color = _DEFAULT_MARKER_COLOR,
    this.hoverColor = _HOVERED_MARKER_COLOR,
    this.onSingleTapUp,
    this.onEnter,
    this.onHover,
    this.onLeave,
  });
}
```

## Defining Marker Sets

**sample-markers.const.dart**
```dart
import 'package:flutter/material.dart';
import 'package:visual_editor/visual_editor.dart';

final SAMPLE_MARKERS_TYPES = [
  MarkerTypeM(
      id: 'UmSuvI9ZcP',
      name: 'Reminder',
      onEnter: (_) {
        print('Entering reminder marker 1');
      },
      onLeave: (_) {
        print('Leaving reminder marker 1');
      },
      onSingleTapUp: (_) {
        print('Tapped reminder marker 1');
      }
  ),
];
```

Create a new controller and provide the markers you desire.
```dart
final _controller = EditorController(
  document: doc,
  selection: const TextSelection.collapsed(offset: 0),
  markersTypes: SAMPLE_MARKERS_TYPES,
);
```

## Storing Markers in The Delta Document
The delta text format can be extended with the marker attribute.

**Example**
```json
[
  {
    "insert": "Lorem ipsum dolor sit amet.\n",
    "attributes": {
      "bold": true,
      "marker": {
        "type": "expert",
        "id": "UmSuvI9ZcP"
      }
    }
  }
]
```

## Adding Markers (WIP)
Via the standard selector or via custom buttons.

## How Markers Are Rendered (WIP)
Similar to highlights that used the selection rendering logic we will render above the TextLine. We can't use TextSpan Styles to render the document markers since the background color already has this role.

Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.