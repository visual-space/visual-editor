![Visual-editor-teaser](https://github.com/visual-space/visual-editor/blob/develop/example/assets/github/visual-editor-teaser.jpg)

Visual Editor is a Rich Text editor for [Flutter] originally forked from [Flutter Quill]. The editor is built around the powerful [Quilljs Delta] document format originally developed by QuillJs. Delta documents can be easily converted to JSON, the encoding is easy to read and modify and offers many extensibility options. This document explains the reasons why we forked [why we forked Quill](https://github.com/visual-space/visual-editor/blob/develop/QUILL_FORK.md).

<img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/github/visual-editor-demo.gif"/>

## How To Start

**Clone via Github**

The current version is getting close to a clean state, ready to be published in pub.dev without major changes. Until published on pub dev you can try it out by linking directly from Github:

**pubspec.yaml**

```
dependencies:
  visual_editor:
    git: https://github.com/visual-space/visual-editor.git
```

**Minimal Example**

You will need a controller that controllers an editor and an editor toolbar.

```dart
final _controller = EditorController.basic();
```

```dart
Column(
  children: [
    EditorToolbar.basic(
      controller: _controller,
    ),
    VisualEditor(
      controller: _controller,
    ),
  ],
)
```

Make sure you don't overwrite the `EditorController` via `setState()`, otherwise you will lose the document's edit history. Which means no more undo, redo with the previous states. In general avoid using `setState()` to update the document. There are methods available in the `EditorController` for such tasks.

**Saving a Document**
```dart
final json = jsonEncode(_controller.document.toDelta().toJson());
```

**Retrieving a Document**
```dart
const blogPost = jsonDecode(response);

final _controller = EditorController(
  document: DocumentM.fromJson(blogPost)
);
```

**Empty Document**

For empty documents the editor can display a placeholder text. This is an empty document:
```json
[
  {
    "insert":"\n"
  }
] 
```
 
For convenience you can import and use the `EMPTY_DELTA_DOC_JSON` constant.

**Delta Or Plain Text**

Visual Editor uses [Delta] operations as an internal data format to describe the attributes of each fragment of text.

```dart
_controller.document.toDelta();
_controller.document.toPlainText();
```

<table cellspacing="0" cellpadding="0" border="0" style="border: 0px; border-collapse:collapse; marin: 60px 0 60px 0">
    <tr style="border: 0px;">
        <td width="50%" style="text-align: center; border: 0px;">
            <a href="https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA" target="_blank" rel="Subscribe to Youtube">
                <img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/github/youtube.jpg"/>
            </a>
            <h2>Youtube</h2>
            <p>Subscribe to our <a href="https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA" target="_blank" rel="Subscribe to Youtube">Visual Coding</a> Youtube channel to learn the skills needed to use and extend Visual Editor. Our episodes go in many topics including Flutter and production ready Software Architecture.</p>
        </td>
        <td width="50%" style="text-align: center; border: 0px;">
            <a href="https://discord.gg/XpGygmXde4" target="_blank" rel="Join on Discord">
                <img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/github/discord.jpg"/>
            </a>
            <h2>Discord</h2>
            <p>Join us on <a href="https://discord.gg/XpGygmXde4" target="_blank" rel="Join on Discord">Visual Editor Discord</a> to get live advice from the maintainers and core users. Our goal is to create a friendly and active support community that shares help and resources.</p>
        </td>
    </tr>
</table>

## Demos & Code Samples
In this repository you can also find a demo app with various pages that showcase all sorts of configurations for the editor. One particularly useful page is the "Delta Sandbox" page. In this page you can see side by side a live editor and a json preview panel. This demo will help you to quickly learn how the Delta format works. 

- You can start the demo app by running main.dart in Android Studio.
- Soon we will have a website with the same demo pages so you don't have to run the samples locally.

## Documentation
Learn more about Visual Editor architecture and how to use the features.

- **[Editor (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/editor/editor.md)** - The widget that renders the document content as commanded by the `EditorController`.
- **[Editor Controller (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/controller/editor-controller.md)** - Controls the editor, and the editor toolbar, exposes useful callbacks.
- **[Documents (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/documents/documents.md)** - Delta documents are used to store text edits and styling attributes.
- **[Toolbar (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/toolbar/toolbar.md)** - Displays buttons used to edit the styling of the text.
- **[Blocks (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/blocks/blocks.md)** - Documents templates are composed of lines of text and blocks of text.
- **[Embeds (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/embeds/embeds.md)** - Visual Editor can display any custom component inside of the documents.
- **[Cursor (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/cursor/cursor.md)** - Indicates the position where new characters will be inserted.
- **[Inputs (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/inputs/inputs.md)** - Hardware Keyboard and Software keyboard.
- **[Rules (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/rules/rules.md)** - Rules execute behavior when certain condition are met.
- **[Selection (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/selection/selection.md)** - Handles the rendering of text selection handles and toolbar.
- **[Highlights](https://github.com/visual-space/visual-editor/blob/develop/lib/highlights/highlights.md)** - Renders temporary text markers sensitive to taps.
- **[Markers](https://github.com/visual-space/visual-editor/blob/develop/lib/markers/markers.md)** - Renders permanent text markers sensitive to taps as part of the delta document.
- **[Performance](https://github.com/visual-space/visual-editor/blob/develop/PERFORMANCE.md)** - Basic tips to follow in order to maintain the editor's performance.
- **[Why Fork Quill](https://github.com/visual-space/visual-editor/blob/develop/CHANGELOG.md)** - Explains the reasons why we forked Quill.
- **[Migration](https://github.com/visual-space/visual-editor/blob/develop/MIGRATING.md)** - A simple guide with instructions to migrate from Flutter Quill.
- **[Changelog](https://github.com/visual-space/visual-editor/blob/develop/CHANGELOG.md)** - Journal of changes made to the visual editor.
  
**For Contributors:**

- **[State Store](https://github.com/visual-space/visual-editor/blob/develop/lib/shared/state-store.md)** - State store architecture decisions.
- **[Project Structure (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/shared/project-structure.md)** - Overview of the major modules and modules folder structure.
- **[Guidelines](https://github.com/visual-space/visual-editor/blob/develop/GUIDELINES.md)** - Coding guidelines for code quality and architecture.
- **[Guidelines](https://github.com/visual-space/visual-editor/blob/develop/COOKBOOK.md)** - These are common API calls used to achieve document changes in the .

## Who Is Using Visual Editor?

- **[Visual Space]** - Social media for engineers, innovators and online teams of enthusiasts.

## Useful Resources
[QuillJs Delta](https://github.com/quilljs/delta) • 
[Designing The Delta Format](https://quilljs.com/guides/designing-the-delta-format) • 
[Language Tool](https://languagetool.org) • 
[Language Server Protocol](https://microsoft.github.io/language-server-protocol) • 
[Word Processing Terminology 1](http://w.sunybroome.edu/basic-computer-skills/functions/word_processing/2wp_terminology.html) • 
[Word Processing Terminology 2](https://www.computerhope.com/jargon/word-processor.htm) • 
[Flutter custom selection toolbar](https://ktuusj.medium.com/flutter-custom-selection-toolbar-3acbe7937dd3)

[Quill]: https://quilljs.com/docs/formats
[Quilljs Delta]: https://github.com/quilljs/delta
[Flutter]: https://github.com/flutter/flutter
[Flutter Quill]: https://github.com/singerdmx/flutter-quill
[Visual Coding]: https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA
[Visual Editor Discord]: https://discord.gg/XpGygmXde4
[Visual Space]: https://visualspace.app