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
Widget _quillToolbar() => QuillToolbar.basic(
    controller: controller ?? QuillController.basic(),
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