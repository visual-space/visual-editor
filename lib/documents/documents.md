# Documents (WIP)

## Delta
Delta is a simple, yet expressive format that can be used to describe contents and changes. The format is JSON based, and is human readable, yet easily parsable by machines. Deltas can describe any rich text document, includes all text and formatting information, without the ambiguity and complexity of HTML.

A Delta is made up of an [Array](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array) of Operations, which describe changes to a document. They can be an [`insert`](#insert-operation), [`delete`](#delete-operation) or [`retain`](#retain-operation). Note operations do not take an index. They always describe the change at the current index. Use retains to "keep" or "skip" certain parts of the document.

Don’t be confused by its name Delta&mdash;Deltas represents both documents and changes to documents. If you think of Deltas as the instructions from going from one document to another, the way Deltas represent a document is by expressing the instructions starting from an empty document.

## Quick Example

```js
// Document with text "Gandalf the Grey"
// with "Gandalf" bolded, and "Grey" in grey
const delta = new Delta([
  { insert: 'Gandalf', attributes: { bold: true } },
  { insert: ' the ' },
  { insert: 'Grey', attributes: { color: '#ccc' } }
]);

// Change intended to be applied to above:
// Keep the first 12 characters, insert a white 'White'
// and delete the next four characters ('Grey')
const death = new Delta().retain(12)
                         .insert('White', { color: '#fff' })
                         .delete(4);
// {
//   ops: [
//     { retain: 12 },
//     { insert: 'White', attributes: { color: '#fff' } },
//     { delete: 4 }
//   ]
// }

// Applying the above:
const restored = delta.compose(death);
// {
//   ops: [
//     { insert: 'Gandalf', attributes: { bold: true } },
//     { insert: ' the ' },
//     { insert: 'White', attributes: { color: '#fff' } }
//   ]
// }
```

## Attributes (WIP)
Attributes defined the characteristics of text. The delta document stores attributes for each operation.

**Attribute Types:**

- **Inline Keys**: bold, italic, small, underline, strikeThrough, link, color, background, placeholder,
- **Block Keys**: header, align, list, codeBlock, blockQuote, indent, direction,
- **Block Keys Except Header**: list, align, codeBlock, blockQuote, indent, direction,
- **Exclusive Block Keys**: header, list, codeBlock, blockQuote, 

**Attribute Scopes**

- **Inline** - refer to https://quilljs.com/docs/formats/#inline
- **Block**, - refer to https://quilljs.com/docs/formats/#block
- **Embeds**, - refer to https://quilljs.com/docs/formats/#embeds
- **Ignore**, - attributes that can be ignored

**Defining New Attributes (WIP)**

## Text Lines, Text Blocks (WIP)

## How Rendering Works (WIP)

- How TextLine works,
- How Styles are applied to Text spans,
- How embeds are rendered

## Conversion From JSON (WIP)

- **DeltaM** -
- **OperationM** -

## Encoding (WIP)
Delta json files are converted to in-memory representation as classes.

TODO Document these:

- **DocumentM** - 
  - **fromJson()** - 
  - **fromDelta()** - 
  - **root** - 
  - **toDelta()** - 
  - **setCustomRules()** - 
  - **setCustomRules()** - 
  - **hasUndo** - 
  - **hasRedo** - 
  - **changes** - 
  - **insert()** - 
  - **delete()** - 
  - **replace()** - 
  - **format()** - 
  - **compose()** - 
  - **undo()** - 
  - **redo()** - 
  - **toPlainText()** - 
  - **getPlainText()** - 
  - **queryChild()** - 
  - **querySegmentLeafNode()** - 
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

## Conversion To Other Data Formats (WIP)
Not yet implemented.

**Read the full article about the delta format:**
- https://github.com/quilljs/delta
- https://quilljs.com/guides/designing-the-delta-format

Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.