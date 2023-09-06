![Visual-editor-teaser](https://github.com/visual-space/visual-editor/blob/develop/example/assets/github/visual-editor-teaser.jpg)

Visual Editor is a Rich Text editor for [Flutter] originally forked from [Flutter Quill]. The editor is built around the powerful [Quilljs Delta] document format originally developed by QuillJs. Delta documents can be easily converted to JSON, the encoding is easy to read and modify and offers many extensibility options. This document explains the reasons [why we forked Quill](https://github.com/visual-space/visual-editor/blob/develop/QUILL_FORK.md) and the improvements that were made.
<p align="center">
  <img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/github/visual-editor-demo.gif"/>
</p>


## Highlights
Highlight custom regions of text with temporary markers that are sensitive to taps and hovering. Highlights are not stored in the delta document. Useful when you want to temporarily showcase a particular range of text. Check out the [highlights docs](https://github.com/visual-space/visual-editor/blob/develop/lib/highlights/highlights.md).

<p align="center">
  <img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/github/highlights.gif"/>
</p>


## Markers
Markers have similar mechanics as highlights but instead of being stored temporarily in the controller they are stored permanently in the document. Markers can be enabled or disabled on demand. Check out the [markers docs](https://github.com/visual-space/visual-editor/blob/develop/lib/markers/markers.md).

<p align="center">
  <img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/github/markers.gif"/>
</p>


## Markers Attachments
Markers can have attachments assigned to them. Custom data can be stored in the attachments. Visual Editor exposes the necessary hooks to implement markers attachments. You can easily customize all the behaviors/rendering. Check out the [markers docs](https://github.com/visual-space/visual-editor/blob/develop/lib/markers/markers.md).

<p align="center">
  <img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/github/markers-attachments.gif"/>
</p>


## Quick Menu
A quick menu can be displayed on top of the current text selection, on top of highlights or markers, or any arbitrary region of text. Visual Editor exposes the necessary hooks to implement custom menus. You can easily customize all the behaviors/rendering.

<p align="center">
  <img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/github/quick-menu.gif"/>
</p>


## Jump To Heading
A document index can be displayed. Tapping the headings will scroll the document to the correct position. Visual Editor exposes the necessary hooks to implement custom menus. You can easily customize all the behaviors/rendering.

<p align="center">
  <img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/github/headings-index.gif"/>
</p>


## Headings Validation
Fancy behaviors such as custom validation of heading lengths can be implemented. We extract a list of headings, we check against custom validation rules and we display highlights where we spot problems. This is by no means a standard feature in rich text editors, therefore we expose the hooks needed to implement it. You can easily customize all the behaviors/rendering.

<p align="center">
  <img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/github/headings-validation.gif"/>
</p>


## Custom Embeds
Inside of delta document you can inject any type of custom embed. Custom embeds store the data necessary to init the embed. In order to render custom embeds client apps need to provide the custom embed builders. Visual Editor exposes the necessary hooks to implement custom menus. You can easily customize all the behaviors/rendering. Check out the [custom embeds docs](https://github.com/visual-space/visual-editor/blob/develop/lib/embeds/embeds.md).

<p align="center">
  <img src="https://github.com/visual-space/visual-editor/blob/develop/example/assets/github/custom-embeds.gif"/>
</p>


## Link Menu
Clicking on a link/text (which is set as a link) opens the link menu, which displays the url of the link, in order to open the link into another tab, beside the URL, there are 3 buttons. One for removing the link, leaving the text as it is without the link attribute. Second the edit link which opens the edit link menu. Third is the copy to clipboard menu.

<div align="center">
  <video src="https://user-images.githubusercontent.com/72706978/222151071-191321dd-24ba-45f7-a3cc-9a393476b4e8.mp4" />
</div>


## Planned Features
- Better links editing UI
- Hashtags
- At notation
- Slash commands
- Coop editing
- Math formulas


## Getting Started
The current version is getting close to a clean state. Visual Editor will soon be ready to be published in pub.dev without major changes. Until then you can use it by linking directly from Github:

```
dependencies:
  visual_editor:
    git: https://github.com/visual-space/visual-editor.git
```

**Minimal Example** - You will need an editor, a toolbar and a controller to link them together.

```dart
final _controller = EditorController();

Column(
  children: [
    EditorToolbar(
      controller: _controller,
    ),
    VisualEditor(
      controller: _controller,
    ),
  ],
)
```

Make sure you don't create a new `EditorController` instance on `setState()`. This mistake degrades performance and you will lose the document's edit history. You can update or change the document directly from the [controller](https://github.com/visual-space/visual-editor/blob/develop/lib/controller/controller.md).

**Saving a Document**
```dart
final json = jsonEncode(_controller.document.toDelta().toJson());
```

**Retrieving a Document**
```dart
const blogPost = jsonDecode(response);

final _controller = EditorController(
  document: DocDeltaM.fromJson(blogPost)
);
```

**Empty Document**

For empty documents the editor can display a placeholder text. This is an empty document. For convenience you can import and use the `EMPTY_DELTA_DOC_JSON` constant.

```json
[{"insert":"\n"}] 
```

**Export Delta Or Plain Text**

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
For a detailed overview of the public API and the code architecture check out our documentation:

- **[Editor](https://github.com/visual-space/visual-editor/blob/develop/lib/editor/editor.md)** - The widget that renders the document content as commanded by the `EditorController`.
- **[Controller](https://github.com/visual-space/visual-editor/blob/develop/lib/controller/controller.md)** - Controls the editor, and the editor toolbar, exposes useful callbacks.
- **[Documents](https://github.com/visual-space/visual-editor/blob/develop/lib/document/document.md)** - Delta documents are used to store text edits and styling attributes.
- **[Toolbar](https://github.com/visual-space/visual-editor/blob/develop/lib/toolbar/toolbar.md)** - Displays buttons used to edit the styling of the text.
- **[Document Tree](https://github.com/visual-space/visual-editor/blob/develop/lib/doc-tree/doc-tree.md)** - Documents templates are composed of lines of text and blocks of text.
- **[Embeds](https://github.com/visual-space/visual-editor/blob/develop/lib/embeds/embeds.md)** - Visual Editor can display any custom component inside of the documents.
- **[Cursor](https://github.com/visual-space/visual-editor/blob/develop/lib/cursor/cursor.md)** - Indicates the position where new characters will be inserted.
- **[Inputs](https://github.com/visual-space/visual-editor/blob/develop/lib/inputs/inputs.md)** - Hardware Keyboard and Software keyboard.
- **[Rules](https://github.com/visual-space/visual-editor/blob/develop/lib/rules/rules.md)** - Rules execute behavior when certain condition are met.
- **[Selection](https://github.com/visual-space/visual-editor/blob/develop/lib/selection/selection.md)** - Handles the rendering of text selection handles and toolbar.
- **[Highlights](https://github.com/visual-space/visual-editor/blob/develop/lib/highlights/highlights.md)** - Renders temporary text markers sensitive to taps.
- **[Markers](https://github.com/visual-space/visual-editor/blob/develop/lib/markers/markers.md)** - Renders permanent text markers sensitive to taps as part of the delta document.
- **[Coop](https://github.com/visual-space/visual-editor/blob/develop/lib/coop/cop.md)** - Instructions on how to run Visual Editor in coop mode (WIP).
  
**For Contributors:**
If you start contributing in the codebase make sure to setup the line char limit to 160 chars. We find the 80 chars default from Flutter way too restrictive.

- **[Why Fork Quill](https://github.com/visual-space/visual-editor/blob/develop/changelog.md)** - Explains the reasons why we forked Quill.
- **[Changelog](https://github.com/visual-space/visual-editor/blob/develop/changelog.md)** - Journal of changes made to the visual editor.
- **[Architecture Overview](https://github.com/visual-space/visual-editor/blob/develop/lib/shared/architecture-overview.md)** - Overview of the editor architecture.
- **[State Store](https://github.com/visual-space/visual-editor/blob/develop/lib/shared/state-store.md)** - State store architecture decisions.
- **[Migration](https://github.com/visual-space/visual-editor/blob/develop/migration-guide.md)** - A simple guide with instructions to migrate from Flutter Quill.


## Who Is Maintaining Visual Editor?
- **[Visual Space]** - We are the team behind the Visual Editor fork. We are building a social media platform for engineers and innovators. This platforms makes heavy use of advanced rich text editing features. Many of these features had to be built from scratch in Visual Editor since they are not yet available in the Flutter ecosystem from other providers.


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