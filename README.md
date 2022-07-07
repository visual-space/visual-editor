![Visual-editor-teaser](https://github.com/visual-space/visual-editor/blob/develop/example/assets/github/visual-editor-teaser.jpg)

Visual Editor is a Rich Text editor for [Flutter] originally forked from [Flutter Quill]. The editor is built around the powerful [Quilljs Delta] document format originally developed by QuillJs. Delta documents can be easily converted to JSON, the encoding is easy to read and modify and offers many extensibility options.

<img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/github/visual-editor-demo.gif"/>

**Why fork Flutter Quill?**

While building the [Visual Space] platform we begun using [Flutter Quill] to render text content for nextgen interactive tutorials and projects. However, we had to deal with issues such as severe lack of documentation, lack of automatic testing and lack of technical support from the maintainers. Therefore, we decided to fork Quill and improve it with additional features and a focus on higher quality standards.

## First contact

1. Clone the repository using "https://github.com/visual-space/visual-editor.git"
2. Run flutter pub get and enable dart editor 
3. If you can't run the main.dart you have to change it with the one from example (example is used to run the demo app)
   -> edit configurations -> set the dart entrypoint with: C:\*your path*\visual-editor\example\lib\main.dart   
4. To push commits we have to ask the moderator to give you access

## How To Start

**Beta Testing**
The current version is not stable enough to be reliable and to be published in pub.dev. Until then you can try it out by linking directly from Github:

**pubspec.yaml**

```
dependencies:
  visual_editor:
    git: https://github.com/visual-space/visual-editor.git
```

**Minimal example**

Make sure you don't overwrite the controller on `build()` or other updates, otherwise you will lose the contents of the history. Which means no more undo, redo with the previous states.
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
  document: DocumentM.fromJson(blogPost),
  selection: TextSelection.collapsed(offset: 0)
);
```

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
- **[Migration](https://github.com/visual-space/visual-editor/blob/develop/MIGRATING.md)** - A simple guide with instructions to migrate from Flutter Quill.
  
**For Contributors:**

- **[State Store](https://github.com/visual-space/visual-editor/blob/develop/lib/shared/state-store.md)** - Explains the state store architecture and how to extend it.
- **[Project Structure (WIP)](https://github.com/visual-space/visual-editor/blob/develop/lib/shared/project-structure.md)** - How the codebase is structured and split in modules.
- **[Guidelines](https://github.com/visual-space/visual-editor/blob/develop/GUIDELINES.md)** - Coding guidelines for improving code quality and architecture clarity.

## Roadmap & Known Issues
These features are currently under developed for [Visual Space]. As soon as they are stable we will release them in the open source repository. We've made an effort to document all the known issues and provide priority and status labels to give you a better understanding when the improvements will be delivered.

- **[Maintainable architecture](https://github.com/visual-space/visual-editor/issues/1)** - Beginner friendly source code. [COMPLETED]
- **[Full documentation](https://github.com/visual-space/visual-editor/issues/2)** - Improved learning materials. [WIP]
- **[Full test coverage](https://github.com/visual-space/visual-editor/issues/3)** - Add test cases from the ground up. [WIP]
- **[Custom Highlights](https://github.com/visual-space/visual-editor/issues/4)** - Highlights custom regions of text that are sensitive to taps [WIP]
- **[Code Color Coding](https://github.com/visual-space/visual-editor/issues/18)**
- **[Tables](https://github.com/visual-space/visual-editor/issues/28)**
- **[Nested bullets on Tab](https://github.com/visual-space/visual-editor/issues/31)** - Pressing tab on the web wont push the bullets into nesting mode.
- **[Layouts](https://github.com/visual-space/visual-editor/issues/41)** - Two columns layouts or other such options.
- **[Styled blocks](https://github.com/visual-space/visual-editor/issues/40)** - Change the styling of a block to make it standout (info, warning, etc).
- **[Search](https://github.com/visual-space/visual-editor/issues/37)**
- **[Plugins Architecture](https://github.com/visual-space/visual-editor/issues/36)** - Enables developers to easily attach middleware to Visual Editor.
- **[Spellchecker](https://github.com/visual-space/visual-editor/issues/35)** 
- **Text to speech** 
- **[Emoji Picker](https://github.com/visual-space/visual-editor/issues/39)** 
- **Custom emoji**
- **Selection menu styling** - Displays a popup menu above selected text for quick common styling actions.
- **Custom selection menu** - Enables developers to add extra buttons in teh quick actions menu.

## Who is using Visual Editor?

- **[Visual Space]** - Next generation interactive tutorials and projects

Send us a message on [Visual Editor Discord] if you want your app to be listed here.

## Additional Resources
[Word Processing Terminology 1](http://w.sunybroome.edu/basic-computer-skills/functions/word_processing/2wp_terminology.html) • 
[Word Processing Terminology 2](https://www.computerhope.com/jargon/word-processor.htm) •
[QuillJs Delta](https://github.com/quilljs/delta) •
[Designing The Delta Format](https://quilljs.com/guides/designing-the-delta-format)

[Quill]: https://quilljs.com/docs/formats
[Quilljs Delta]: https://github.com/quilljs/delta
[Flutter]: https://github.com/flutter/flutter
[Flutter Quill]: https://github.com/singerdmx/flutter-quill
[Visual Coding]: https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA
[Visual Editor Discord]: https://discord.gg/XpGygmXde4
[Visual Space]: https://visualspace.app