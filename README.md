![Visual-editor-teaser](https://github.com/visual-space/visual-editor/blob/develop/example/assets/visual-editor-teaser.jpg)

Visual Editor is a Rich Text editor for [Flutter] originally forked from [Flutter Quill]. The editor is built around the powerful [Quilljs Delta] document format originally developed by QuillJs. Delta documents can be easily converted to JSON, the encoding is easy to read and modify and offers many extensibility options.

<img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/visual-editor-demo.gif"/>

**Why fork Flutter Quill?**

While building the [Visual Space] platform we begun using [Flutter Quill] to render text content for next generation interactive tutorials and projects. However, we had to deal with issues such as severe lack of documentation and testing plus a lack of technical support from the maintainers. Therefore, we decided to fork Quill and improve it with additional features and higher quality standards. Soon we will be publishing the entire Visual Kit, a set of widgets built for productivity apps.

## How To Start

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
  document: Document.fromJson(blogPost),
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
                <img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/youtube.jpg"/>
            </a>
            <h2>Youtube</h2>
            <p>Subscribe to our <a href="https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA" target="_blank" rel="Subscribe to Youtube">Visual Coding</a> Youtube channel to learn the skills needed to use and extend Visual Editor. Our episodes go in many topics including Flutter and production ready Software Architecture.</p>
        </td>
        <td width="50%" style="text-align: center; border: 0px;">
            <a href="https://discord.gg/XpGygmXde4" target="_blank" rel="Join on Discord">
                <img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/discord.jpg"/>
            </a>
            <h2>Discord</h2>
            <p>Join us on <a href="https://discord.gg/XpGygmXde4" target="_blank" rel="Join on Discord">Visual Editor Discord</a> to get live advice from the maintainers and core users. Our goal is to create a friendly and active support community that shares help and resources.</p>
        </td>
    </tr>
</table>

## Documentation
Learn more about Visual Editor architecture and how to use the features.

- **[Delta](https://github.com/visual-space/visual-editor/blob/develop/lib/delta/delta.md)** - Delta documents are used to store text edits and styling attributes.
- **[Toolbar](https://github.com/visual-space/visual-editor/blob/develop/lib/toolbar/toolbar.md)** - Displays buttons used to edit the styling of the text.
- **[Highlights](https://github.com/visual-space/visual-editor/blob/develop/lib/highlights/highlights.md)** - Renders temporary text markers sensitive to taps.

## Roadmap
These features are currently under developed for [Visual Space]. As soon as they are stable we will release them in the open source repository.

- **[Maintainable architecture](https://github.com/visual-space/visual-editor/issues/1)** - Beginner friendly source code. [WIP]
- **[Full documentation](https://github.com/visual-space/visual-editor/issues/2)** - Improved learning materials. [WIP]
- **[Full test coverage](https://github.com/visual-space/visual-editor/issues/3)** - Add test cases from the ground up.
- **[Custom Highlights](https://github.com/visual-space/visual-editor/issues/4)** - Highlights custom regions of text that are sensitive to taps [WIP]
- **Code Color Coding**
- **Tables**
- **Nested bullets on Tab** - Pressing tab on the web wont push the bullets into nesting mode.
- **Layouts** - Two columns layouts or other such options.
- **Styled blocks** - Change the styling of a block to make it standout (info, warning, etc).
- **Search**
- **Plugins Architecture** - Enables developers to easily attach middleware to Visual Editor.
- **Spellchecker** 
- **Text to speech** 
- **Emoji Picker** 
- **Custom emoji**
- **Selection menu styling** - Displays a popup menu above selected text for quick common styling actions.
- **Custom selection menu** - Enables developers to add extra buttons in teh quick actions menu.

## Known Issues
- Toolbar does not trigger cursor pointer (in example page)
- The "embeds missing" warning should be listed only once at init. Currently it's repeated many times
- The demo content is outdated.
- There are 2 ways to upload images in the web build.
- The background for the modal that uploads images is missing color.
- Tab key does not work as expected on web.
- Checkboxes don't show pointer cursor on web.
- Links don't show pointer cursor on web.
- Headings are completely overridden by the size attribute/selector. Other editors give priority to the last feature that modified the text size.
- Switch to next input by pressing TAB (on web)
- Typing inside a link will split the link. This is abnormal behaviour, links should ingest the new characters.
- Links can't be edited (afaik).
- Nest bullets when pressing Tab. Currently it's possible only with the indentation controls.

## Who is using Visual Editor?

- **[Visual Space]** - Next generation interactive tutorials and projects

Send us a message on [Visual Editor Discord] if you want your app to be listed here.

## Additional Resources
[Word Processing Terminology 1](http://w.sunybroome.edu/basic-computer-skills/functions/word_processing/2wp_terminology.html) •
[Word Processing Terminology 2](https://www.computerhope.com/jargon/word-processor.htm)

[Quill]: https://quilljs.com/docs/formats
[Quilljs Delta]: https://github.com/quilljs/delta
[Flutter]: https://github.com/flutter/flutter
[Flutter Quill]: https://github.com/singerdmx/flutter-quill
[Visual Coding]: https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA
[Visual Editor Discord]: https://discord.gg/XpGygmXde4
[Visual Space]: https://visualspace.app