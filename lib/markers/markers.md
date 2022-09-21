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
Before using markers the types of markers need to be defined. If no information is provided, then our default marker type is used.

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
There are two ways to add markers:
- Via the toolbar - First select some text that you want marked. Then click on the markers dropdown. Select a the desired marker type.
- Via the controller - An alternative is to add them via controller triggered by custom buttons.

```dart
controller.addMarker('expert'); // Any of the markers types that have been provided
```

## List Of Markers
Get a list of all markers. Each marker provides the position relative to text and the custom data. Positions can be used to render other custom text decorations in perfect alignment with the text.

## Removing Markers (WIP)
Multiple markers can be added on top of each other. Inspecting multiple markers at once for content is not easily done without creating a complex overview panel. Removing markers is best done by inspecting and removing them one by one to make sure no desired marker is removed. Therefore, the clear styling button does not remove markers in bulk. Also for the same reason we limited the markers dropdown to only adding markers. Removing markers from the dropdown is very prone to removing the wrong marker. Also the UX would be super complicated and hard to master. Again, the easiest and most precise way is to tap on the markers and use the options menu.

## Storing Custom Data In Markers (WIP)
Advanced use cases might require that markers store custom data such as UUIDs or whatever else the client app developers require. A callback method can be used to generate the custom data when a new marker is added from the dropdown. Beware that these IDs could be generated and then discarded if the author decided to cancel the edit. Therefore make sure you don't populate your DB eagerly unless the document was saved.

A marker defines it's type (class) and additional data. The "data" attribute stores custom params as desired by the client app (uuid or serialised json data). It's up to the client app to decide how to use the data attribute. One idea is to use UUIDS that point to a separate list of entries which describe the various attributes of a marker. For example a developer might want to render a bunch of stats that are repeating on a large set of the markers of the app. Therefore instead of repeating the same data inline in the entire doc it's better to reference these values from a separate list. In this case using the data to store an UUID will be good enough.

On the other hand, if the dev knows that most of the markers will have few and unique attributes than he can store the attributes in the "data" attribute itself. The "data" attribute will be returned by the callbacks methods invoked on hover and tap. Multiple markers can use the same "data" values to trigger the same common behaviours. In essence there are many ways this attribute can be put to good use. It's also possible not to use it at all and just render highlights that don't have any unique data assigned.

## Hiding Markers
Despite being part of the delta document the markers can be hidden on demand. Toggling markers from the editor controller can be useful for situations where the developers want to clear the text of any visual guides and show the pure rich text. Highlights can be toggled all at once via the controller. This might be useful if you want to render the text without any extra decorations.

```dart
_controller.toggleMarkers(); // Enables or disables the visibility of all markers
_controller.getMarkersVisibility(); // Query if markers are disabled
```

For certain scenarios it might be desired to init the editor with the markers turned off. Later the markers can be enabled using the editor controller API.

```dart
 VisualEditor(
  controller: _controller,
  scrollController: ScrollController(),
  focusNode: _focusNode,
  config: EditorConfigM(
    markersVisibility: true,
  ),
),
```

## How Markers Are Rendered (WIP)
Similar to highlights that used the selection rendering logic we will render above the TextLine. We can't use TextSpan Styles to render the document markers since the background color already has this role.

**Toggle Markers**

The `_toggleMarkers$` stream is used to trigger `markForPaint()` in every `EditableTextLineRenderer` (similar to how the cursor updates it's animated opacity). We can't use `_state.refreshEditor.refreshEditor()` because there's no new content, therefore Flutter change detection will not find any change, so it wont trigger any repaint.


Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.