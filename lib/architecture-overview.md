# Architecture Overview (WIP)
Here you can learn the general architecture of the editor, what major parts are present and how they work together.


## Project Structure
The entire codebase is split two major areas: main library code and the demo pages. The main library is split in multiple feature modules. Each module fallows mostly the same pattern of organization. 

```
/const
/controllers
/models
/services
/state
/widgets
doc.md
```


## Delta Documents
Delta is a simple, yet expressive format that can be used to describe contents and changes. The format is JSON based, and is human readable, yet easily parsable by machines. Deltas can describe any rich text document, includes all text and formatting information, without the ambiguity and complexity of HTML. A Delta is made up of an list of Operations, which describe changes to a document. They can be an `insert`, `delete` or `retain`. They always describe the change at the current index. Use retains to "keep" or "skip" certain parts of the document. Reading the various json samples we have in the demo pages project will help you quickly learn how delta docs work. Also try the Sandbox demo page where you can see in real time how a document changes.


## Attributes
Attributes defined the characteristics of text. The delta document stores attributes for each operation. Not all operations are required to define attributes.


## Editor Controller
The editor controller has two major roles: synchronizing the state between the editor and the toolbar and exposing the public API for the editor. Internally the editor mirrors the most important methods of all major modules. In the old Quill codebase this file used to have around 2000 lines of code. We made a significant effort to trim it down bellow 200. Get familiar with all the methods exposed in the public API. It will greatly improve your development abilities. It's highly recommended to read the [Hierarchy of Code](https://github.com/visual-space/visual-editor/blob/develop/lib/controller/controller.md) section in the controller document.


## Document Controller
The actual document (pure data) editing happens by calling compose() or other methods from the documentController level. Since both of editor service and document controller are public APIs we had to use short names (less expressive). Therefore to solve the confusion between `editorController.compose()` and `documentController.compose()` remember that the editor level has to coordinate more systems along with the updates of the document. Which means that the actual pure data editing of the document content happens in documentController.


## Pure Data Models (WIP)
In the initial Quill architecture (before forking) the Document models had a large number of methods. This made them really hard to understand because code and data were mixed together. We made a large refactoring effort to convert all models to pure data models. This reduced the effort required to understand the models. This means we transitioned from OOP API design (methods attached to document) to a pure functional API design (pure data models and utils). We retained the short OOP naming style, aka fluent API). This approach makes it a lot easier for new lib contributors to understand the architecture.


## Toolbar
By default, the toolbar provides the typical list of rich text editing actions. The toolbar is receives access to the internal editor state store via the `EditorControler`. Then this state store is passed to the individual buttons. The buttons themselves are subscribed to the `runBuild$` stream. Whenever the document is changed then the main editor `build()` method is invoked via the `runBuild$` stream. This means that the toolbar buttons trigger the build process as well at the same time with the editor build. During the build cycle the buttons read values from the `StylesService`.


## Build
The `RunBuildService` provides easy access to the build trigger. After the document changes have been applied and the gui elements have been updated, it's now time to update the document widget tree.


## Document Tree
Documents templates are composed of lines of text and blocks of text. The blocks themselves can have different styling and roles. The `DocTreeService` builds the widgets of the doc-tree as described by the document nodes. Each new break line represents a new text line, which generates an EditableTextLine widget. Inside a text line, each range of text with an unique set of attributes is considered a node. For each node the EditableTextLine generates a TextSpan with the correct test style applied. These widgets are `EditableTextLine` or `EditableTextBlock`. Each time changes are made in the document or the state store the editor build() will render once again the document tree. After the build cycle is complete we are caching rectangles for several layers: selection, highlights, markers, headings. Provides the callback for handling checkboxes.


## Proxies, Renderbox (WIP)
Honestly, not fully understood for now :) Any help in documenting them is fully appreciated.


## Delta vs Nodes
Document models can be initialised empty or from json data or delta models. Internally, in the editor controller there exists an additional representation: nodes. Nodes is a list of objects that represent each individual fragment of text with unique styling. Islands made of nodes of identical styling get merged in one single continuous chunk. When a document is initialised, the delta operations are converted to nodes and attached to the root node. The build() process maps the document nodes to styled text spans in the widget tree. 

All nodes inherit from `NodeM`. The node inherits from the `LinkedListEntry`. This means all nodes can be linked in a linked list structure. This is by far the most efficient data structure that can be used to iterate through the document. All nodes are linked to prev and next but also to parent Which means we have the best of both worlds: linked lists and directed acyclic graphs. In the end all nodes are listed under the root node of document tree. 


## Rules
Visual Editor (as in Quill) has a list of rules that are executed after each document change. Custom rules can be added on top of the core rules. Rules are split in 3 sets: delete, format, insert. Rules are contain logic to be executed once a certain trigger/condition is fulfilled. For ex: One rule is to break out of blocks when 2 new white lines are inserted. Such a rule will attempt to go trough the entire document and scan for lines of text that match the condition: 2 white lines one after the other. Once such a pair is detected, then we modify the second line styling to remove the block attribute.


## State Store
Visual Editor has a lot of internal state to manage: the document, cursor position, text selection, the pressed keys, etc. One of the major changes since forking from Quill was to isolate all the state in a dedicated pure data layer. This change yields greatly improved code readability. In essence, the editor code flow boils down to 2 steps: preparing the raw data to be processed and then calling the build method to update the UI. There are no widgets running in parallel consuming different data sources. Therefore, existing state store libs for single page apps are not suitable. Instead we developed a simple internal state store solution using basic Dart data classes and a stream to trigger the build cycle.


## Internal References
One annoying issue that is still present is the need to access the scopes of widgets that implement the overrides requested by Flutter or the `FocusNode` or `ScrollController` that the user provides. To avoid creating more prop drilling these scopes are all cached in the state store in a dedicated `EditorReferences` class. Although storing these reference in the state store, infringes on the "pure data" principle we still implemented this trick because it reduces the amount of prop drilling required in the code.


## Input Connection Service
When a user start typing, new characters are inserted by the remote input. The remote input is the input used by the system to synchronize the content of the input with the state of the software keyboard or other input devices. The remote input stores only plain text. The actual rich text is stored in the editor state store as a DocumentM. The editor observes the states of the remote input and diffs them. The diffs are then applied to the internal document. The remote input does not contain any styling. All the styling is stored in the editor document and is managed by the `DocumentController`.


## Text Selection
Text can be selected on screen. Additional widgets can be rendered to control the text actions. One might expect that the copy paste menus are implemented by the system. Actually these are fully controller by Visual Editor. We currently have 2 ways of customizing the selection menu. More details: [Selection](https://github.com/visual-space/visual-editor/blob/develop/lib/selection/selection.md).

- **Attaching To Markers (new)** - When the selection callbacks have emitted we can use the rectangles data to place any attachment anywhere. Recommended when you want to place atypical looking markers related to the lines of selected text.
- **TextSelectionControls (old)** - Standard flutter procedure using a custom TextSelectionControls. Recommended when you want to display standard selection menu with custom buttons.


## Gesture Detector
Multiple callbacks can be called for one sequence of input gestures. An ordinary `GestureDetector` configured to handle events like tap and double tap will only recognize one or the other. This widget detects: the first tap and then, if another tap down occurs within a time limit, the double tap. Most gestures end up calling runBuild() to refresh the document widget tree.


# Links
Links in text can be edited or added using the toolbar or link menu. The`AutoFormatMultipleLinksRule` automatically adds a link attribute to matching text. `AutoFormatMultipleLinksRule` Applies link formatting to inserted text that matches the URL pattern. It determines the affected words by retrieving the word before and after the insertion point and searches for matches within them. If there are no matches, the method does not apply any format. If there are matches, it builds a base delta for the insertion and a formatter delta for formatting changes. The formatter delta only includes link formatting when necessary. After processing all matches, the method composes the base delta and formatter delta to obtain the resulting change delta.


## Markers
Renders permanent text markers sensitive to taps. Markers are defined in the delta document. Unlike highlights, markers change the delta document by adding attributes. The markers are rendered on top of the text. Markers are sensitive to taps and hovers. Custom marker types with custom colors and behaviours can be defined.


## Highlights
Highlights are temporary text markers sensitive to taps. Highlights can be added and removed at runtime. They do not change the underlying document in any shape or form. The highlights are simply rendered on top of the text. Highlights are sensitive to taps and hovers. Custom colors can be defined.


## Embeds
Visual Editor can display arbitrary custom components inside of the documents such as: image, video, tweets, etc. An embed node has a length of 1 character. Any inline style can be applied to an embed, however this does not necessarily mean the embed will look according to that style. For instance, applying "bold" style to an image gives no effect, while adding a "link" to an image actually makes the image react to user's action. Custom embed builders can be provided to render custom elements in the page.


## History
The document model uses these stacks to record the history of edits. Edits can be recorded at a regular interval (to save memory space). A max amount of history states can be saved (to save memory space). User only means that we are in coop editing mode. In coop mode the history stacks can be rebased with the remote document.


## Search (WIP)


## Coop Editing (TBD)


## Slash Commands (TBD)


## Tags And Handles (TBD)


## Tables (TBD)


## Contributing Guidelines
All the Pull Requests raised on the Visual Editor repository will have to comply with the following list of rules. The list is made of common sense clean code practices adapted to Flutter projects.

- **Keep all methods short, especially build(), initState(), subscribe()** - The code flow has to be easily distinguishable and identifiable. Every single class and entry method such as: build(), initState(). subscribe(). All entry points will must be boiled down form large blobs of code down to small clearly named methods. This will improve the readability of the code by leaps and bounds.
- **Always update docs**
- **Always write tests**
