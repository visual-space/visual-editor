# Toolbar

Offers users the possibility to edit the text properties. By default several actions are available:

- Undo, Redo
- Font size
- Bold
- Italic
- Underline
- Strikethrough
- Inline code snippet
- Text color
- Background fill
- Insert content(video, images)
- Justify
- Stretch
- Reset styling
- Heading styles
- Lists (numbered, bullet)
- Checkbox
- Quote
- Indent Right
- Indent Left
- Add Link

Toolbars configurable, every option can be disabled:

```dart
Widget _editorToolbar() =>
    EditorToolbar.basic(
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
    );
```

Toolbar can be displayed on a single row or multiple rows.
For mobile users it can be dragged to search through options.
The alignment of the icons can be customized.
The icons can be replaced with customized ones.

```dart
 Widget _editorToolbar() =>
    EditorToolbar.basic(
      multiRowsDisplay: false,
      toolbarIconAlignment: WrapAlignment.start,
      customIcons: [],
    );
```

## Toolbar buttons

Visual Editor lib exports all the buttons that form the toolbar. This means you can create a new
custom toolbar out of the buttons VisualEditor provides plus your own custom buttons. To keep them
in sync with your editor every single button receives the controller as an input. Unlike other
classes of the code base the buttons do receive the controller explicitly.

```dart
// Extended toolbar
EditorToolbar.basic(
  controller: controller,
  customIcons: [
    EditorCustomButtonM(
      icon: Icons.favorite,
      onTap: () {
        // Add custom behavior here  
      }
    ),
  ],
),

// Custom independent button
ColorButton(
  icon: Icons.color_lens,
  iconSize: toolbarIconSize,
  controller: controller,
  background: false,
  buttonsSpacing: 10,
  iconTheme: iconTheme,
),
```

Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us
on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more
about the architecture of Visual Editor and other Flutter apps.