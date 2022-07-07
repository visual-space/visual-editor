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

final MARKERS_TYPES = [
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
  markersTypes: MARKERS_TYPES,
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
        "data": "UmSuvI9ZcP"
      }
    }
  }
]
```

## Adding Markers (WIP)
Markers can be added by selecting the text and pressing the toolbar button for adding markers. An alternative is to add them via controller triggered by custom buttons. 

## Removing Markers (WIP)
Multiple markers can be added on top of each other. Inspecting multiple markers at once for content is not easily done without creating a complex overview panel. Removing markers is best done by inspecting and removing them one by one to make sure no desired marker is removed. Therefore, the clear styling button does not remove markers in bulk. Also for the same reason we limited the markers dropdown to only adding markers. Removing markers from the dropdown is very prone to removing the wrong marker. Also the UX would be super complicated and hard to master. Again, the easiest and most precise way is to tap on the markers and use the options menu.

## Storing Custom Data In Markers (WIP)
Advanced use cases might require that markers store custom data such as UUIDs or whatever else the client app developers require. A callback method can be used to generate the custom data when a new marker is added from the dropdown. Beware that these IDs could be generated and then discarded if the author decided to cancel the edit. Therefore make sure you don't populate your DB eagerly unless the document was saved.

## How Markers Are Rendered (WIP)
Similar to highlights that used the selection rendering logic we will render above the TextLine. We can't use TextSpan Styles to render the document markers since the background color already has this role.

Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.