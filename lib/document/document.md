# Delta Documents
Delta is a simple, yet expressive format that can be used to describe contents and changes. The format is JSON based, and is human readable, yet easily parsable by machines. Deltas can describe any rich text document, includes all text and formatting information, without the ambiguity and complexity of HTML. A Delta is made up of an list of Operations, which describe changes to a document. They can be an `insert`, `delete` or `retain`. They always describe the change at the current index. Use retains to "keep" or "skip" certain parts of the document. Reading the various json samples we have in the demo pages project will help you quickly learn how delta docs work. Also try the Sandbox demo page where you can see in real time how a document changes.

**Delta format docs:**
- [Delta](https://github.com/quilljs/delta)
- [Designing the delta format](https://quilljs.com/guides/designing-the-delta-format)

**Basic Title and Text Sample**
```json
[
  {
    "insert": "Read Only"
  },
  {
    "insert": "\n",
    "attributes": {
      "header": 1
    }
  },
  {
    "insert": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n"
  }
]
```

## Document Controller
The actual document (pure data) editing happens by calling compose() or other methods from the documentController level. Since both of editor service and document controller are public APIs we had to use short names (less expressive). Therefore to solve the confusion between `editorController.compose()` and `documentController.compose()` remember that the editor level has to coordinate more systems along with the updates of the document. Which means that the actual pure data editing of the document content happens in documentController.


## Pure Data Models
In the initial Quill architecture (before forking) the Document models had a large number of methods. This made them really hard to understand because code and data were mixed together. We made a large refactoring effort to convert all models to pure data models. This reduced the effort required to understand the models. This means we transitioned from OOP API design (methods attached to document) to a pure functional API design (pure data models and utils). We retained the short OOP naming style, aka fluent API). This approach makes it a lot easier for new lib contributors to understand the architecture.

- **Models & Utils** - Since the models no longer have methods that means devs will need to know two files: models and utils. This is one slight drawback of this architecture. Since only advanced users manipulate the document outside of the editor controller we think that's not a good enough reason to retain the old OOP style models.


## Attributes
Attributes defined the characteristics of text. The delta document stores attributes for each operation. Not all operations are required to define attributes.

**Attribute Types**

- **Inline Keys** - bold, italic, small, underline, strikeThrough, link, color, background, placeholder,
- **Block Keys** - header, align, list, codeBlock, blockQuote, indent, direction,
- **Block Keys Except Header** - list, align, codeBlock, blockQuote, indent, direction,
- **Exclusive Block Keys** - header, list, codeBlock, blockQuote, 

**Attribute Scopes**

- **Inline** - Inline attributes apply styles to a random slice of text at any position.
- **Block** - Block attributes apply styles to a large block of text (code block or bullets list)
- **Embeds** - Embeds are used to add additional content that is not supported by the editor (video, interactive widgets, etc).
- **Ignore** - Attributes that can be ignored


## Nodes (WIP)
Document models can be initialised empty or from json data or delta models. Internally, in the editor controller there exists an additional representation: nodes. Nodes is a list of objects that represent each individual fragment of text with unique styling. Islands made of nodes of identical styling get merged in one single continuous chunk. When a document is initialised, the delta operations are converted to nodes and attached to the root node. The build() process maps the document nodes to styled text spans in the widget tree.

All nodes inherit from `NodeM`. The node inherits from the `LinkedListEntry`. This means all nodes can be linked in a linked list structure. This is by far the most efficient data structure that can be used to iterate through the document. All nodes are linked to prev and next but also to parent Which means we have the best of both worlds: linked lists and directed acyclic graphs. In the end all nodes are listed under the root node of document tree.

- **DocumentM** -
- **DeltaM** - 
- **RootM** - 
- **ContainerM** - 
- **NodeM** - 
- **LineM** - 
- **TextM** - 
- **LeafM** - 
- **OperationM** - 
- **StyleM** - 
- **NodeM** - 
- **EmbeddableM** - 

- **insert** -
- **delete** -
- **retain** -


## History (WIP)


## Conversion To Other Data Formats (TBD)


## Edit Delta Docs In Dart Server
You can edit delta docs on the server side using `DocumentController`. This can come in handy for a couple of scenarios:
- **SEO** - You can get retrieve the plain text of a delta doc and then render it as a plain old html document using whatever server side technology you desire.
- **Elastic Search** - If you need to write a search feature for a large number of documents, once again, you will need the plain text server side. Again running the visual editor on the server side is super handy.
- **Coop Editing** - In case you want to implement a master server to compare the edits of multiple users, again you can run doc edits on the dart server itself.

**Importing Visual Editor Server**
By importing the server side library we ensure that no `dart:ui` dependencies are imported. Note that both the frontend and server versions of the library use the same code. They are just different export files.

```dart
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:visual_editor/visual-editor-server.dart';

//...
// Convert delta text to plain text
final document = DeltaDocM.fromJson(jsonDecode(deltaText));
final plainText = DocumentController(document, null, null).toPlainText();
```


## Avoiding material/dart:ui imports on server
This section includes detailed explanation of what architectural modifications were needed to be able to run Visual Editor on the server. Several approaches were attempted until we landed on the final solution.
- **Conditional Imports To Avoid Importing Material In Doc Controller When On Server** - Because we run the library on the server we do not have access at UI proprieties. Because of that, we needed to avoid any file that uses `flutter/material`, `dart:ui` etc. In some cases we made 2 types of files, one for the normal use and one for the server (eg. `marker.model.dart` and `marker.model.server.dart`) which are imported conditionally.
- **Conditional Import Does Not Work On Android** - After testing we spotted that the trick does not work with the mobile build. The mobile build attempts to load the trimmed down server version of `MarkerM` on mobile thus leading to a bunch of static checking errors. After some more research (Fed '24) we concluded that there's no way to differentiate server only. Therefore we have to explore other ways to deal with `MarkerM`. `MarkerM` had some properties (rectangles data to render the marker) that were passed at runtime from the doc tree to the state store for convenience. Instead of requesting the rectangles again when hovering a marker we now have them cached. We had to split this cache from the marker models and separate it in a dedicated map. This cut the remaining dependence on the server side.
- **Conditional Imports for Markers Models - Does Not Work** - For markers we collected some UI pixel data to store it in the markers model such that it's easier to render. The normal model uses `material` to render rectangles, text selection etc. and for the server version we kept the proprieties but we used `dynamic`. For now some features are disabled on server. If we need them, we can go to the extreme solution of replicating our own models and them mapping to material models when passing the document to the doc tree.
- **MarkerM and MarkerM** - Once we figured out that the conditional imports wont be working we tried creating 2 layers of models. The basic one and the enriched one. The goals was to add the material models on the extended model and use them only in the rendering pipeline. Since we collect the rectangles only after rendering that should have worked. However there was also `TextSelection` used from material to store the base and offset. The text selection is used later when we need to delete markers. Again for convenience it was added on the marker model post init. The trouble is that this step happens on document init in the `DocumentController`. Which means once again we are forced to import material in `DocumentController`.
- **Duplicating Material Models** - To completely detach these chunks of code from material we had to create our own replicas/models after material. These are pure data and have not dependence on material. Once we migrated the models to this setup most of the code could be reverted to the original state. The only changes that needed to be done were to map out to material models once again in the rendering pipeline in the place where we paint rectangles in the canvas. Everything else works as is.

