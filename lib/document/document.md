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
const restored = delta.getComposedDelta(death);
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


## Solved Issues
**update() added an extra \n**

(!) Calling `update()` will trigger two operations: `clear()` and `compose()`. `clear()` will use `replace()` to cleanup the entire document until we are left with `[{"insert":"\n"}]`. `compose()` will then use the new delta to append it to the document. `documentController.compose()` will trigger an insert on the `rootNode` (nodes list). Reminder: `clear()` has updated both the delta and `rootNode` to contain an empty line with a simple break line inside. This means we are adding empty rootNode "\n" + new data: "abc\n" and we will get "abc\n\n".

* **Attempt1** - Deleting in the controller delta the new line \n character such that we can do "" + "abc\n". This approach has some serious after effects because the delta and the `rootNode` go out of sync.
* **Attempt2** - Deleting the newline in the rootNode after the insert. However first time it was done the wrong way. I was removing the first child in the list thus leaving the document empty regardless of the delta provided by `update()`. This seems to work fine when you have just an empty field being updated with empty doc. However it no longer works when you attempt to update with a regular document that has chars. Another issue was that I did not update the internal delta of the controller to match the new state of the `rootNode`. Once again things were going crazy with further interactions due to the mismatch between internal delta and rootNode.
* **Final Attempt** - I realised that I need to delete the last line of the rootNode. Also, we need to make sure this is done ONLY when compose() is called from `clear()`. That's why I created the `overrideRootNode` param. This entire setup might look like a hack, but there's simply no way to get rid of the double \n\n when updating the doc. The entire nodes manipulation code is built under the assumption that a document line will always end with \n. Therefore there's no simple way of getting rid of the initial \n of an empty doc. Thus we are left only with the option presented here: to remove the double \n if we now it was generated by update().


Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.