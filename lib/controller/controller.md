# Editor Controller
The editor controller has two major roles: synchronizing the state between the editor and the toolbar and exposing the public API for the editor. Internally the editor mirrors the most important methods of all major modules. In the old Quill codebase this file used to have around 2000 lines of code. We made a significant effort to trim it down bellow 200. Get familiar with all the methods exposed in the public API. It will greatly improve your development abilities.


## Public API
Quick overview of the entire public API. Just by analysing these methods you can already understand a lot about the editor architecture.

* **Constructor** - These methods are provided by the client developer.
  * `onReplaceText()` - Invoked each time a character is inserted or removed (it also can be used to insert new objects in the document if we replace the last character)
  * `onDelete()` - Invoked when characters are deleted
  * `onSelectionCompleted()` - Invoked after release the pointer when selecting text
  * `onSelectionChanged()` - Invoked when the selection is changed
  * `onBuildComplete()` - Invoked after the layout is fully built. Useful for attaching elements to markers.
  * `onScroll()` - Invoked when the editor is scrolling. Useful for updating the position of attached elements.
**History**
  * `undo()`
  * `redo()`
* **Document**
  * `getPlainText()` - Returns plain text for each node within selection
  * `update()` - Update editor with a new document.
      * `emitEvent` - It defaults to true which means that by default any change (update) made to the document will fire the callbacks `onReplaceText()` and `onReplaceTextCompleted()`. In certain scenarios when the editor is used in a combination with the state store we might want to disable the emission of a new event. If the state store update the document then we want to prevent the callbacks from being fired. That's when we use `emitEvent: false`. If the editor has been changed by the user via typing then we want to push this change to the state store. Then we prefer to emit events (call callbacks) as per default behaviour.
  * `replace()`
  * `compose()`
* **Text Styles**
  * `formatTextStyle()`
  * `formatText()`
  * `formatSelection()` - Applies an attribute to a selection of text
  * `getSelectionStyle()` - Only attributes applied to all characters within this range are included in the result
  * `getAllIndividualSelectionStyles()` - Returns all styles for each node within selection
  * `getAllSelectionStyles()` - Returns all styles for any character within the specified text range
  * `getHeadingsByType()` - Useful for listing the headings of the document in a separate index component.
* **Cursor**
  * `moveCursorToStart()`
  * `moveCursorToPosition()`
  * `moveCursorToEnd()`
* **Selection**
  * `updateSelection()`
* **Nodes**
  * `queryNode()` - Given offset, find its leaf node in document
* **Highlights**
  * `addHighlight()` - Adds a temporary highlights in the document. Cannot be persisted on the server
  * `removeHighlight()`
  * `removeAllHighlights()`
* **Markers**
  * `addMarker()` - Adds a permanent marker in the document. Can be persisted on the server
  * `toggleMarkers()` - Hide or show markers
  * `toggleMarkerByTypeId()` - Hide or show just a certain type of markers
  * `getMarkersVisibility()` - Query if markers are disabled
  * `isMarkerTypeVisible()` - Query if certain type of markers are disabled
  * `getAllMarkers()` - Get a list of all markers. Each marker provides the position relative to text and the custom data.
  * `deleteMarkerById()` - Delete all markers with the same id from the document.
* **Headings**
  * `getHeadings()` - Get a list of all headings. The default heading type is H1 but it can be customized in the controller


## Hierarchy of Code
There are 2 major ares of concern: updating the UI and manipulating the pure data documents. These 2 concerns are split in two major layers: `EditorService` and `DocumentController`. When exploring the codebase you will find we have `compose()` and other methods defined 2 times. Without a clear understanding how the UI and pure data handling are separated you will have a tough time figuring out how they work together. 

- **EditorController** - Exposes a large number of public methods that can query or mutate the document. These methods are mirrored from the various services that are available in the code base.
- **EditorService** - The most important methods are provided by the `EditorService`. They handle the most important work of updating the document and reflecting the document changes by updating the UI of the editor.
- **DocumentController** - Contains the logic for manipulating the pure data delta document and the logic needed to convert it to a list of nodes that can be rendered by the `DocTreeService`.

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


## Use controller.update() instead of setState()
Triggering `setState()` in the parent widget of the `VisualEditor` widget should be avoided as much as possible. Once you built the page, you don't want to trigger a rebuild of the entire editor. Even if Flutter is clever enough to avoid any major work in the rendering layer it still has to run change detection. And for a large document this adds up. Especially on low power devices such as smartphones. To avoid such scenarios it is recommended that you use the controller API to update the document instead of `setState()` on the editor parent widget.

- **Avoid setState() on text select** - One common mistake is to react to the selection change in the editor by setting state in the parent. This will induce a needless build cycle in the editor. For example, in the Markers demo page you can see an editor and bellow it a stats panel with numbers indicating the selection extent. Notice that in the demo page implementation we have made special effort to avoid triggering `setState()` on the entire page when the selection changes. Our solution (one of many possible solutions) was to send the selection extend numbers via a stream to the sibling component that renders them.


## Inserting new elements at the end of the document
For example if you want to have a button that every time is pressed adds a new empty line at the end of the document we can simply replace the last element of the document with the empty line.

```dart
final docLen = _controller.document.length;
_controller.replace(docLen - 1, 0, '\n', null);
```


## Adding text attributes
The attributes are used to apply a different style to a piece of text (bold, italic, etc.). Everything which is not simple text has at least an attribute. To apply attributes without directly interacting with the text (i.e by pressing a button) we can call the format text method from the controller with the desired attribute. Here we apply the h1 attribute to the empty line created above. In this way, by pressing a single button we can create a new empty line with h1 attribute

```dart
 _controller.formatText(docLen, 0, AttributesAliasesM.h1);
```


## Calling update() used to add an extra \n. Was Fixed
This was an rather peculiar and difficult bug to fix. I've listed here the entire debugging process. Hopefully you can use it to learn a thing or two about the editor controller and the document controller. Now let's jump to the explanation. Calling `update()` will trigger two operations: `clear()` and `compose()`. `clear()` will use `replace()` to cleanup the entire document until we are left with `[{"insert":"\n"}]`. `compose()` will then use the new delta to append it to the document. `documentController.compose()` will trigger an insert on the `rootNode` (nodes list). Reminder: `clear()` has updated both the delta and `rootNode` to contain an empty line with a simple break line inside. This means we are adding empty rootNode "\n" + new data: "abc\n" and we will get "abc\n\n".

* **Attempt1** - Deleting in the controller delta the new line \n character such that we can do "" + "abc\n". This approach has some serious after effects because the delta and the `rootNode` go out of sync.
* **Attempt2** - Deleting the newline in the rootNode after the insert. However first time it was done the wrong way. I was removing the first child in the list thus leaving the document empty regardless of the delta provided by `update()`. This seems to work fine when you have just an empty field being updated with empty doc. However it no longer works when you attempt to update with a regular document that has chars. Another issue was that I did not update the internal delta of the controller to match the new state of the `rootNode`. Once again things were going crazy with further interactions due to the mismatch between internal delta and rootNode.
* **Final Attempt** - I realised that I need to delete the last line of the rootNode. Also, we need to make sure this is done ONLY when compose() is called from `clear()`. That's why I created the `overrideRootNode` param. This entire setup might look like a hack, but there's simply no way to get rid of the double \n\n when updating the doc. The entire nodes manipulation code is built under the assumption that a document line will always end with \n. Therefore there's no simple way of getting rid of the initial \n of an empty doc. Thus we are left only with the option presented here: to remove the double \n if we now it was generated by update().