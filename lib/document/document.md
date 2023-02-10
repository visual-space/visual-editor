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

