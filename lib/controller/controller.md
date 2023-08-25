# Editor Controller (WIP)
The editor controller is a class used to sync the state between the editor input itself and the editor toolbar. PLease read [main.md]() to get an overview of how all major services and controllers fit together. This will help you better understand why EditoController exists and what it does.


## Document Controller (to be moved in main.md)
WIP - Explain why Doc controller was created. Mention pure data models.


## Hierarchy of Code Flow (to be moved in main.md)
- **EditorController** - Exposes a large number of public methods that can query or mutate the document. These methods are mirrored from the various services that are available in the code base. 
- **EditorService** - The most important methods are provided by the `EditorService`. They handle the most important work of updating the document and reflecting the document changes by updating the UI of the editor.
- **EditorController** - Contains the logic for manipulating the pure data delta document and the logic needed to convert it to a list of nodes that can be rendered by the `DocTreeService`.

**Updating The Editor UI vs Document Pure Data Editing**
The `EditorService` contains the logic that orchestrates the editor UI systems with the DocumentController (pure data editing). It does not contain the document mutation logic. The `EditorService` delegates this logic to the DocumentController. The actual document (pure data) editing happens by calling `compose()` or other methods from the `DocumentController` level. Since both of these are public APIs (service and controller) we had to use short names (less expressive). Therefore to solve the confusion between `editorController.compose()` and `documentController.compose()` remember that the editor level has to coordinate more systems along with the updates of the document. Which means that the actual pure data editing of the document content happens in documentController.

**Hierarchy Of Methods**
At first sight you might get quite confused to see `editorController.replace()`, `editorService.replace()` and `DocumentController.replace()`. All of the methods from `EditorService` are available in public by being mirrored in the `EditorController`. So when we think of `EditorService` you can already expect most public methods to be exposed to the public in `EditorController`. So all we care about in our analysis is the `EditorService` and `DocumentController`.
  
- **main.updateEditingValue()** - The main class has an override provided by the remote input connection. This override is basically the method that gets invoked each time an user writes something in the editor. Whenever you need to capture/manage/review changes originating from the user inputing text, this is the place.
- **editorService.update()** - Updates an entire document. It clears the old one and composes the new one in one single step.
- **editorService.clear()** - Removes the content of the entire document. Uses `editorService.replace()`.
- **editorService.replace()** - Unlike `update()` this method can be used to update only a specific part of the document. It delegates the doc mutation logic to `documentController.replace()` and in some special cases to `documentController.compose()`. It handles invocation of callbacks, triggering `build()` and some additional logic related to styling new lines of code when they need to cary over styles form the previous line.
- **documentController.replace()** - Converts to `insert()` and `delete()` and returns a change delta.
- **documentController.insert()** - Runs the insert rules before calling `compose()`.
- **documentController.delete()** - Runs the delete rules before calling `compose()`.
- **documentController.compose()** - The final method that applies changes in the document is `documentController.compose()`. All other methods use it to apply the final computed change set.


## Public methods (WIP)
This is a list of the public methods that are available in the controller and some short description explaining when/for what to use them.

**Constructor**

These methods are provided by the client developer.

* `onReplaceText()` - Invoked each time a character is inserted or removed (it also can be used to insert new objects in the document if we replace the last character)
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
    * `emitEvent` - It defaults to true which means that by default any change (update) made to the document will fire the callbacks `onReplaceText()` and `onReplaceTextCompleted()`. In certain scenarios when the editor is used in a combination with the state store we might want to disable the emission of a new event. If the state store update the document then we want to prevent the callbacks from being fired. That's when we use `emitEvent: false`. If the editor has been changed by the user via typing then we want to push this change to the state store. Then we prefer to emit events (call callbacks) as per default behaviour.
* `replace()`
* `compose()`

**Text Styles**

* `formatTextStyle()`
* `formatText()`
* `formatSelection()` - Applies an attribute to a selection of text
* `getSelectionStyle()` - Only attributes applied to all characters within this range are included in the result
* `getAllIndividualSelectionStyles()` - Returns all styles for each node within selection
* `getAllSelectionStyles()` - Returns all styles for any character within the specified text range
* `getHeadingsByType()` - Useful for listing the headings of the document in a separate index component.

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
* `toggleMarkerByTypeId()` - Hide or show just a certain type of markers
* `getMarkersVisibility()` - Query if markers are disabled
* `isMarkerTypeVisible()` - Query if certain type of markers are disabled
* `getAllMarkers()` - Get a list of all markers. Each marker provides the position relative to text and the custom data.
* `deleteMarkerById()` - Delete all markers with the same id from the document.

**Headings**

* `getHeadings()` - Get a list of all headings. The default heading type is H1 but it can be customized in the controller.

* Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.