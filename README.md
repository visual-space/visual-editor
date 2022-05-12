# Visual Editor
**Fork of Flutter Quill - Current status, Under Major Refactoring. Expect some features here and there to be affected / disabled.**

Visual Editor is a Rich Text editor for Flutter originally forked from Flutter Quill. The editor is built around the powerful Delta document format originally developed by QuillJs. Delta documents can be easily converted to JSON, the encoding is easy to read and modify and offers many extensibility options.

Our core motivation to fork Quill was the severe lack of documentation and testing plus a lack of support from the maintainers when it comes to receiving technical support. Considering that we plan to release many more open source Flutter widgets, starting with the rich text editor was a no brainer.

## Planned Features
- Improved, easy to digest architecture
- Full docs
- Full test coverage
- Highlights
- Code Samples
- Tables
- Nested bullets
- Layouts
- Styled blocks
- Color coding for source code
- Themes
- Search
- Bug fixes

[Visual Coding] - Tutorials about Visual Editor and software architecture

[FlutterQuill] - The Original repo that we forked

## How To Start

Minimal example, toolbar and editor with a shared controller:

```
QuillController _controller = QuillController.basic();
```

```dart
Column(
  children: [
    QuillToolbar.basic(controller: _controller),
    Expanded(
      child: Container(
        child: QuillEditor.basic(
          controller: _controller,
          readOnly: false,
        ),
      ),
    )
  ],
)
```

## Input / Output
This library uses [Quill] as an internal data format.

* `_controller.document.toDelta()` - Extract the deltas.
* `_controller.document.toPlainText()` - Extract plain text.

## Saving a document as JSON

**Saving a document**
```
var json = jsonEncode(_controller.document.toDelta().toJson());
```

**Retrieving a document**
```
const blogPost = jsonDecode(response);

_controller = QuillController(
  document: Document.fromJson(blogPost),
  selection: TextSelection.collapsed(offset: 0)
);
```

This readme will be expanded with detailed instruction on how to use Visual Editor. Currently we are ongoing a deep cleanup effort.

[Quill]: https://quilljs.com/docs/formats
[Flutter]: https://github.com/flutter/flutter
[FlutterQuill]: https://github.com/singerdmx/flutter-quill
[Visual Coding]: https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA
