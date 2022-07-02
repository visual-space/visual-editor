# Toolbar
Using the toolbar users can edit the text properties. By default several actions are available:
- Undo, Redo
- Font size
- Bold
- Italic
- Underline
- Strikethrough
- Inline code snippet
- Text color
- Background fill
- Insert image
- Insert video
- Insert camera picture
- Justify left
- Justify center
- Justify right
- Stretch
- Reset styling
- Heading 1
- Heading 2
- Heading 3
- Numbered list
- Bullet list
- Checkbox
- Quote
- Indent Right
- Indent Left
- Add Link

Toolbars can be configured:

```
Widget _editorToolbar() => EditorToolbar.basic(
    controller: controller ?? EditorController.basic(),
    showImageButton: true,
    showVideoButton: true,
    showColorButton: false,
    showBackgroundColorButton: false,
    showUnderLineButton: false,
    showClearFormat: false,
    showIndent: false,
    showDividers: false,
    showHeaderStyle: true,
    showUndo: false,
    showRedo: false,
    toolbarIconAlignment: WrapAlignment.start,
  );
```

## Toolbar buttons
Visual Editor lib exports all the buttons that form the toolbar. This means you can create a new custom toolbar out of the buttons VisualEditor provides plus your own custom buttons. To keep them in sync with your editor every single button receives the controller as an input. Unlike other classes of the code base the buttons do receive the controller explicitly.

```
ColorButton(
    icon: Icons.color_lens,
    iconSize: toolbarIconSize,
    controller: controller,
    background: false,
    iconTheme: iconTheme,
),
```

Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.