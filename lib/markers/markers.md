# Markers
Renders permanent text markers sensitive to taps. Markers are defined in the delta document. Unlike highlights, markers change the delta document by adding attributes. The markers are rendered on top of the text. Markers are sensitive to taps and hovers. Custom marker types with custom colors and behaviours can be defined. 


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
  final Function(MarkersTypeM marker)? onExit;

  const MarkerTypeM({
    required this.id,
    required this.name,
    this.color = _DEFAULT_MARKER_COLOR,
    this.hoverColor = _HOVERED_MARKER_COLOR,
    this.onSingleTapUp,
    this.onEnter,
    this.onHover,
    this.onExit,
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
      onEnter: (marker) {
        print('Entering reminder marker 1');
      },
      onExit: (marker) {
        print('Leaving reminder marker 1');
      },
      onSingleTapUp: (marker) {
        print('Tapped reminder marker 1');
      }
  ),
];
```

Create a new editor and controller pair and then provide the markers you desire.
```dart
final _controller = EditorController(
  document: doc,
);
```
```dart
Widget _editor() => VisualEditor(
  controller: _controller,
  config: EditorConfigM(
    selection: const TextSelection.collapsed(offset: 0),
    markersTypes: MARKERS_TYPES,
  ),
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
        "id": "1160109744764000",
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
// Add any of the markers types that have been provided.
controller.addMarker('expert'); 
```


## List Of Markers
Get a list of all markers. Each marker provides the position relative to text and the custom data. Positions can be used to render other custom text decorations in perfect alignment with the text.


## Removing Markers (WIP)
Multiple markers can be added on top of each other. Inspecting multiple markers at once for content is not easily done without creating a complex overview panel. Removing markers is best done by inspecting and removing them one by one to make sure no desired marker is removed. Therefore, the clear styling button does not remove markers in bulk. Also for the same reason we limited the markers dropdown to only adding markers. Removing markers from the dropdown is very prone to removing the wrong marker. Also the UX would be super complicated and hard to master. Again, the easiest and most precise way is to tap on the markers and use the options menu.


## Storing Custom Data In Markers (WIP)
Advanced use cases might require that markers store custom data such as UUIDs or whatever else the client app developers require. A callback method can be used to generate the custom data when a new marker is added from the dropdown. Beware that these IDs could be generated and then discarded if the author decided to cancel the edit. Therefore make sure you don't populate your DB eagerly unless the document was saved.

A marker defines it's type (class) and additional data. The "data" attribute stores custom params as desired by the client app (uuid or serialised json data). It's up to the client app to decide how to use the data attribute. One idea is to use UUIDS that point to separate objects which provide additional info for a marker. For example a developer might want to render a bunch of stats that are repeating on a large set of the markers of the app. Therefore instead of repeating the same data inline in the entire doc it's better to reference these values from a separate list. In this case using the data to store an UUID for the descriptor object will be enough.

On the other hand, if the dev knows that most of the markers will have few and unique attributes than he can store the attributes in the "data" attribute itself. The "data" attribute will be returned by the callbacks methods invoked on hover and tap. Multiple markers can use the same "data" values to trigger the same common behaviours. In essence there are many ways this attribute can be put to good use. It's also possible not to use it at all and just render highlights that don't have any unique data assigned.


## Hiding Markers
Despite being part of the delta document the markers can be hidden on demand. Toggling markers from the editor controller can be useful for situations where the developers want to clear the text of any visual guides and show the pure rich text. Highlights can be toggled all at once or just for certain types of markers via the controller. This might be useful if you want to render the text without any extra decorations.

```dart
_controller.toggleMarkers(); // Enables or disables the visibility of all markers
_controller.getMarkersVisibility(); // Query if markers are disabled
_controller.toggleMarkerByTypeId(); // Enables or disables the visibility of certain type of markers
_controller.isMarkerTypeVisible(); // Query if certain type of markers is disabled
```

For certain scenarios it might be desired to init the editor with the markers turned off. Later the markers can be enabled using the editor controller API.

```dart
VisualEditor(
  controller: _controller,
  config: EditorConfigM(
    markersVisibility: true,
  ),
),
```


## Delete markers
Markers can be deleted from the document. All markers with the same id will be removed.

```dart
controller.deleteMarkerById(_marker.id);
```


## Markers Attachments
Markers provide support for attachments by returning their pixel coordinates and dimensions for positioning in text. Based on this information any widget can be linked to a marker. Keep in mind that markers are not widgets, so a simple Overlay from Flutter wont do the trick. Markers are rendered as painted rectangles in a canvas on top of the text. Even if markers are hidden, marker attachments still work correctly. Therefore the only way to simulate attached widgets is by positioning them to the exact coordinates. This page demonstrates such a setup. Attachments can be used render elements such as the markers options menu or delete button.

**How Markers Attachments Work And How To Use Them**

Basically each time the editor text is update the main `build()` method is triggered which in turn does a bunch of stuff to render the lines of text. I've taped into the logic that computes the rectangles for all markers. After the main `build()` completes there's a`addPostFrameCallback` that queries all the lines of text in the editor and retrieves a list of markers and their rendered rectangles. This information is cached to be later retrieved on demand.

Additionally I've added 2 callbacks for the editor:

- one for notifying when a build cycle is complete
- one for notifying when a scroll step is complete

```dart
_controller = EditorController(
  document: document,
);
```
```dart
Widget _editor() => VisualEditor(
  controller: _controller,
  config: EditorConfigM(
    markerTypes: [
      //...
    ],
    onBuildComplete: _updateMarkerAttachments,
    onScroll: _updateMarkerAttachments,
  ),
);
```
You can hook into these callback to run whatever rendering logic you need for attachments. Basically you have:
- Markers data
- Markers rectangles (viewport coordinates)
- Scroll offset
- Viewport dimensions

Using this data you can compute yourself if you want to render something on screen or not, to wherever you want to render it. There's an entire sample page `MarkersAttachmentsPage` indicating how to piece together this setup (has nice comments to guide you). Beware that in the page I made dedicated effort to avoid using `setState()` on the parent page. This is essential for preserving scroll performance. Follow the sample step by step and you will figure out precisely how to render anything you want at any position relative to the markers. It's also possible to adjust this code for situation where the editor is configured as non scrollable. You'll have to use the outer `ScrollController` but the setup is similar.

There's still a list of smaller issues that I'm currently documenting as tickets but overall you should be able to use it successfully.

This is a simplified example to showcase the parts involved. For a complete example check out the **markers-attachments.page.dart**
```dart
final StreamController<List<MarkerM>> markers$;

_controller = EditorController(
  document: document,
);

@override
Widget build(BuildContext context) =>
  Row(
    children: [
      MarkersAttachments(
        markers$: _markers$,
      ),
      VisualEditor(
        controller: _controller!,
        scrollController: _scrollController,
        focusNode: _focusNode,
        config: EditorConfigM(
          markerTypes: [
            // MarkerTypeM(), ...
          ],
          onBuildComplete: _updateMarkerAttachments,
          onScroll: _updateMarkerAttachments,
        ),
      ),
    ]
  );

// From here on it's up to the client developer to decide how to draw the attachments.
// Once you have the build and scroll updates + the pixel coordinates, you can do whatever you want.
// (!) Inspect the coordinates to draw only the markers that are still visible in the viewport.
// (!) This method will be invoked many times by the scroll callback.
// (!) Avoid heavy computations here, otherwise your page might slow down.
// (!) Avoid setState() on the parent page, setState in a smallest possible widget to minimise the update cost.
void _updateMarkerAttachments() {
  final markers = _controller?.getAllMarkers() ?? [];
  _markers$.sink.add(markers);
}
```

**Using different markers type for different needs. Ex: one marker type could be used to render attachments**

In some situations, we want to use one of the markers' types for rendering attachments only. We don't want to show them in the editor. Why would a developer need this? Say for example you have created a marker type to label spoiler content. And you also want to allow people to assign comments to that particular spoiler. However if you decide to remove the spoiler you don't want to lose the existing comments tied to that particular region. One way to avoid this scenario is to use two types of markers. One is used to label the spoiler and renders visible markers. The other is used to link comments to the text. They are both created at once when a text fragmnent is marked as spoiler. However these marker types can be removed one by one. Which means you can delete the spoiler and no longer show it on screen while keeping the comments still linked to the text.

*json after implementation*
```json
{
  "insert": "Text\n",
  "attributes": {
    "markers": [
      {
        "id": "5471139741564000",
        "type": "spoiler"
      },
      {
        "id": "5456839741567000",
        "type": "comments",
        "data": "comments data or uuid"
      }
    ]
  }
}
```


## Displaying A Custom Widget When Tapping A Marker
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

Init the editor with callbacks defined for the markers types.

```dart
Widget _editor() => VisualEditor(
  controller: _controller,
  scrollController: _scrollController,
  focusNode: _focusNode,
  config: EditorConfigM(
    onScroll: _updateQuickMenuPosition,
    
    // Hide menu while the selection is changing
    onSelectionChanged: (selection, rectangles) {
      _hideQuickMenu();
    },
    
    markerTypes: [
      MarkerTypeM(
        id: 'expert',
        name: 'Expert',
        onAddMarkerViaToolbar: (type) => 'fake-id-1',
        
        // Use your own logic for rendering and positioning the attached widget(s)
        onSingleTapUp: _displayQuickMenuOnMarker,
      ),
    ],
  ),
);
```


## How Markers Are Rendered (explained for maintainers)
Similar to highlights that used the selection rendering logic we will render above the TextLine. We can't use TextSpan Styles to render the document markers since the background color already has this role.

**Toggle Markers**

The `_toggleMarkers$` stream is used to trigger `markForPaint()` in every `EditableTextLineRenderer` (similar to how the cursor updates it's animated opacity). We can't use `_state.runBuild.runBuild()` because there's no new content, therefore Flutter change detection will not find any change, so it wont trigger any repaint.

**Hover Markers**

In Flutter we don't have any built in mechanic for easily detecting hover over random stretches of text. Therefore we have to write our own code for detecting hovering over markers. When the editor is initialised we store all the markers in the state store. Once the build() method is executed we have references to all the rendering classes for every single class. Using a callback after build we query every single line to check if it has markers, and if so we request the rectangles needed to draw the markers. Unlike highlights, markers are sliced per line by default (when DeltaM is converted to DeltaDocM). For each marker we cache also the local to global offset of the line where it is hosted. This offset will be essential to align the pointer coordinates with the markers rectangles coordinates. 

Once we have the rectangles we cache them by deep cloning the markers to include this information. When the user pointer enters the editor screen space then the TextGestures widget matches the correct action (onHover). In the on hover method we check every single marker to see if any of the rectangles are intersected by the pointer. Once one or many markers are matched we then cache the ids. On every single hover event we compare if new ids have been added or removed. For each added or removed marker we run the corresponding callbacks defined by the marker type. Then we cache the new hovered markers in the state store and trigger a new editor build (layout update). When the editor is running the build cycle each line will check again for markers that it has to draw and will apply the hovering color according to the hovered markers from the state stare.


## Get Offset Compared Relative To The Document.
When dealing with extraction of rectangles for tasks such as rendering highlights or markers, one might often need to learn the offset relative to the document, or relative to the line of text. There are two highly useful methods for this purpose `localToGlobal()`. Learning this information can be useful later for retrieving the rectangles of a selection of text. Knowing the `docRelPosition` is essential if you are building code that attempts to position elements relative to arbitrary text selections. You can find multiple examples of how these methods are used by reading `SelectionMenuPage`, `MarkersAttachmentsPage`, `RectanglesService`, etc.

```dart

// Local to Global
final docRelPosition = underlyingText.localToGlobal(
  const Offset(0, 0),
  ancestor: state.refs.renderer,
);

// Global to Local
final localPosition = targetChild.globalToLocalPosition(position);
final childLocalRect = targetChild.getLocalRectForCaret(localPosition);
```

Another essential method to know as a extension or core contributor in Visual Editor is `getRectanglesFromNode()`. You can use rectangles and docRelativePosition to compute where on screen a certain region of text is located. Once you know these coordinates many other things are possible, such as linking arbitrary overlay widgets to random positions in the text. This method has been used numerous times in several critical parts of the editor. Drawing the selection, the markers, the highlights, the quick menu, etc. Follow code examples related to these features to better understand what this methods does.

```dart
markers.forEach((marker) {
  final rectangles = getRectanglesFromNode(node, underlyingText);
  // ...
}
```