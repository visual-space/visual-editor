# Editor Controller (WIP)
The editor controller is a class used to sync the state between the Editor input itself and the Editor toolbar. The Controller exposes several useful callbacks that can be used by the client app to detect changes in the document content.

## Public methods (WIP)

**Constructor**

These methods are provided by the client developer.

* `onReplaceText()` - Invoked each time a character is inserted or removed
* `onDelete()` - Invoked when characters are deleted
* `onSelectionCompleted()` - Invoked after release the pointer when selecting text
* `onSelectionChanged()` - Invoked when the selection is changed
* `onBuildComplete()` - Invoked after the layout is fully built. Useful for attaching elements to markers.
* `onScroll()` - Invoked when the editor is scrolling. Useful for updating the position of attached elements.

**History**

* `undo()`
* `redo()`

**Document**

* `getPlainText()` - Returns plain text for each node within selection
* `update()` - Update editor with a new document.
* `replaceText()`
* `compose()`

**Text Styles**

* `formatTextStyle()`
* `formatText()`
* `formatSelection()` - Applies an attribute to a selection of text
* `getSelectionStyle()` - Only attributes applied to all characters within this range are included in the result
* `getAllIndividualSelectionStyles()` - Returns all styles for each node within selection
* `getAllSelectionStyles()` - Returns all styles for any character within the specified text range

**Cursor**

* `moveCursorToStart()`
* `moveCursorToPosition()`
* `moveCursorToEnd()`

**Selection**

* `updateSelection()`

**Nodes**

* `queryNode()` - Given offset, find its leaf node in document

**Highlights**

* `addHighlight()`
* `removeHighlight()`
* `removeAllHighlights()`

**Markers**

* `addMarker()` - Add marker of type
* `toggleMarkers()` - Hide or show markers
* `toggleMarkersByTypes()` - Hide or show just certain types of markers
* `getMarkersVisibility()` - Query if markers are disabled
* `getMarkersVisibilityByTypes()` - Query if certain types of markers are disabled
* `getAllMarkers()` - Get a list of all markers. Each marker provides the position relative to text and the custom data.
* `deleteMarkerById()` - Delete all markers with the same id from the document.


**Headings**

* `getHeadings()` - Get a list of all headings. The default heading type is H1 but it can be customized in the controller.

* Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.