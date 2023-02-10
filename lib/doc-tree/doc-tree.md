# Document Tree
Documents templates are composed of lines of text and blocks of text. The blocks themselves can have different styling and roles. The `DocTreeService` builds the widgets of the doc-tree as described by the document nodes. Each new break line represents a new text line, which generates an EditableTextLine widget. Inside a text line, each range of text with an unique set of attributes is considered a node. For each node the EditableTextLine generates a TextSpan with the correct test style applied. These widgets are `EditableTextLine` or `EditableTextBlock`. Each time changes are made in the document or the state store the editor build() will render once again the document tree. After the build cycle is complete we are caching rectangles for several layers: selection, highlights, markers, headings. Provides the callback for handling checkboxes.


## Text Lines (WIP)
TODO Explain the relations between: EditableBlock, EditableTextBlock, and the other widgets.


## Text Blocks


## Proxies (WIP)


## Links (WIP)


## Markers (WIP)


## Pixel Coordinates
Snippet used to convert the position of the pointer in X and Y to a TextSelection extent.
```dart
final position = _coordinatesService.getPositionForOffset(
  details.globalPosition,
  state,
);
```

