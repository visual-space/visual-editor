![Visual-editor-teaser](https://github.com/visual-space/visual-editor/blob/develop/example/assets/github/visual-editor-teaser.jpg)

Visual Editor is a Rich Text editor for [Flutter] originally forked from [Flutter Quill]. The editor is built around the powerful [Quilljs Delta] document format originally developed by QuillJs. Delta documents can be easily converted to JSON, the encoding is easy to read and modify and offers many extensibility options.

<img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/github/visual-editor-demo.gif"/>

## Why Fork Flutter Quill?
While building the [Visual Space] platform we begun using [Flutter Quill] to render text content for nextgen interactive tutorials and projects. Initially we attempted to extended Quill with additional features such as custom highlights. However, we had to deal with major issues such as opaque architecture, severe lack of documentation, lack of automatic testing and a complete lack of technical support from the maintainers. Therefore, we decided to fork Quill and improve it with additional features and a focus on higher quality standards. This [reddit post](https://www.reddit.com/r/FlutterDev/comments/uq340b/ive_decided_to_fork_flutter_quill_rich_text/) contains a detailed explanation. 

## Major Improvements Compared To Quill
Check out the [changelog](https://github.com/visual-space/visual-editor/blob/develop/CHANGELOG.md) for a detailed review of what was changed. Also there's a [migration](https://github.com/visual-space/visual-editor/blob/develop/MIGRATING.md) guide for users migrating from Quill.

- **[Maintainable Architecture](https://github.com/visual-space/visual-editor/issues/1)** - Source code was split in modules. Files were split in smaller files. A distinct state management layer was introduced. Class names have been simplified. We replaced the `ChangedNotifiers` with standalone streams. We simplified the `build()` methods. We merged the `Editor` and `RawEditor` in one file.
- **[Extended Documentation](https://github.com/visual-space/visual-editor/issues/2)** - We are continuously adding in depth documentation to make it easier for new contributors to extend the source code. Quill has very little documentation and it lacks in depth explanation over the architecture. Our goal is to cover both new features and the legacy ones in detailed documentation.
- **[Demo Pages](https://github.com/visual-space/visual-editor/issues/63)** - We've provided simple, concise demo pages to exemplify how to use Visual Editor for the various tasks you have.
- **[Automatic Testing](https://github.com/visual-space/visual-editor/issues/3)** - In Quill there's no automatic testing available. New contributions constantly break the legacy code. The PR's are not policed enough. We started by adding tests and we are slowly increasing the coverage of the tests.
- **[Custom Highlights](https://github.com/visual-space/visual-editor/issues/4)** - Highlights custom regions of text that are sensitive to taps and hovering.
- **[Custom Markers](https://github.com/visual-space/visual-editor/issues/69)** - Same as highlights but instead of being temporary in the controller they are permanent in the document.
- **[Markers Attachments](https://github.com/visual-space/visual-editor/issues/117)** - Markers provide support for attachments by returning their pixel coordinates and dimensions for positioning in text. Based on this information any widget can be linked to a marker.
- **[Active Discord Support Community](https://discord.gg/XpGygmXde4)** - You'll be able to get quick answers from the maintainers of the repo. We are available almost at all times to answer your questions. Including general Flutter and Dart questions.

## How To Start

**Unstable Code, Under Refactoring**

The current version is not stable enough to be reliable and to be published in pub.dev. Until then you can try it out by linking directly from Github:

**pubspec.yaml**

```
dependencies:
  visual_editor:
    git: https://github.com/visual-space/visual-editor.git
```

**Minimal example**

Make sure you don't overwrite the `EditorController` via `setState()`, otherwise you will lose the contents of the history. Which means no more undo, redo with the previous states. In general avoid using `setState()` to update the document. There are methods available in the `EditorController` for such tasks.

```dart
final _controller = EditorController.basic();
```

```dart
Column(
  children: [
    EditorToolbar.basic(
      controller: _controller,
    ),
    Expanded(
      child: Container(
        child: VisualEditor.basic(
          controller: _controller,
        ),
      ),
    )
  ],
)
```

**Saving a document**
```dart
final json = jsonEncode(_controller.document.toDelta().toJson());
```

**Retrieving a document**
```dart
const blogPost = jsonDecode(response);

final _controller = EditorController(
  document: DocumentM.fromJson(blogPost)
);
```

**Empty document**

When a document is empty a custom placeholder should be insert. An empty document looks like:
```json
[
  {
    "insert":"\n"
  }
] 
```
 
For convenience you can use a constant: `const EMPTY_DELTA_DOC_JSON = '[{"insert":"\\n"}]'`

**Delta or plain text**

Visual Editor uses [Delta] objects as an internal data format to describe the attributes of each fragment of text.

```dart
_controller.document.toDelta(); // Extract the deltas
_controller.document.toPlainText(); // Extract plain text
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

- **[Editor (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/editor/editor.md)** - Renders the document content as commanded by the `EditorController`.
- **[Editor Controller (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/controller/editor-controller.md)** - Controls the editor, sync the toolbar, exposes useful callbacks.
- **[Documents (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/documents/documents.md)** - Delta documents are used to store text edits and styling attributes.
- **[Toolbar (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/toolbar/toolbar.md)** - Displays buttons used to edit the styling of the text.
- **[Blocks (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/blocks/blocks.md)** - Documents templates are composed of lines of text and blocks of text.
- **[Embeds (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/embeds/embeds.md)** - Visual Editor can display any custom component inside of the documents.
- **[Cursor (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/cursor/cursor.md)** - Indicates the position where new characters will be inserted.
- **[Inputs (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/inputs/inputs.md)** - Hardware Keyboard and Software keyboard.
- **[Rules (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/rules/rules.md)** - Rules execute behavior when certain condition are met.
- **[Selection (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/selection/selection.md)** - Rules execute behavior when certain condition are met.
- **[Highlights](https://github.com/visual-space/visual-editor/blob/develop/lib/highlights/highlights.md)** - Renders temporary text markers sensitive to taps.
- **[Markers](https://github.com/visual-space/visual-editor/blob/develop/lib/markers/markers.md)** - Renders permanent text markers sensitive to taps as part of the delta document.
- **[Performance](https://github.com/visual-space/visual-editor/blob/develop/PERFORMANCE.md)** - Basic tips to follow in order to maintain the editor's performance.
- **[Migration](https://github.com/visual-space/visual-editor/blob/develop/MIGRATING.md)** - A simple guide with instructions to migrate from Flutter Quill.
- **[Changelog](https://github.com/visual-space/visual-editor/blob/develop/CHANGELOG.md)** - Journal of changes made to the visual editor.
  
**For Contributors:**

- **[State Store](https://github.com/visual-space/visual-editor/blob/develop/lib/shared/state-store.md)** - Explains the state store architecture and how to extend it.
- **[Project Structure (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/shared/project-structure.md)** - How the codebase is structured and split in modules.
- **[Guidelines](https://github.com/visual-space/visual-editor/blob/develop/GUIDELINES.md)** - Coding guidelines for improving code quality and architecture clarity.

## Who is using Visual Editor?

- **[Visual Space]** - Next generation interactive tutorials and projects

Send us a message on [Visual Editor Discord] if you want your app to be listed here.

## Useful Resources
[QuillJs Delta](https://github.com/quilljs/delta) •
[Designing The Delta Format](https://quilljs.com/guides/designing-the-delta-format) •
[Language Tool](https://languagetool.org) •
[Language Server Protocol](https://microsoft.github.io/language-server-protocol) •
[Word Processing Terminology 1](http://w.sunybroome.edu/basic-computer-skills/functions/word_processing/2wp_terminology.html) • 
[Word Processing Terminology 2](https://www.computerhope.com/jargon/word-processor.htm)

[Quill]: https://quilljs.com/docs/formats
[Quilljs Delta]: https://github.com/quilljs/delta
[Flutter]: https://github.com/flutter/flutter
[Flutter Quill]: https://github.com/singerdmx/flutter-quill
[Visual Coding]: https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA
[Visual Editor Discord]: https://discord.gg/XpGygmXde4
[Visual Space]: https://visualspace.app