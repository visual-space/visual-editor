# Toolbar
By default, the toolbar provides the typical list of rich text editing actions. The toolbar is receives access to the internal editor state store via the `EditorControler`. Then this state store is passed to the individual buttons. The buttons themselves are subscribed to the `runBuild$` stream. Whenever the document is changed then the main editor `build()` method is invoked via the `runBuild$` stream. This means that the toolbar buttons trigger the build process as well at the same time with the editor build. During the build cycle the buttons read values from the `StylesService`.

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


## Wrap Versus Vertical Scroll
Toolbar can be displayed on a single row or multiple rows. For mobile users it can be dragged to search through options. The alignment of the icons can be customized. The icons can be replaced with customized ones.

```dart
 Widget _editorToolbar() =>
    EditorToolbar.basic(
      multiRowsDisplay: false,
      toolbarIconAlignment: WrapAlignment.start,
      customIcons: [],
    );
```


## Toolbar buttons
Visual Editor lib exports all the buttons that form the toolbar. This means you can create a new custom toolbar out of the buttons VisualEditor provides plus your own custom buttons. To keep them in sync with your editor every single button receives the controller as an input. Unlike other  classes of the code base the buttons do receive the controller explicitly.

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

## State Management In The Toolbar Buttons
Notice that we don't have full control over the timing of loading the main widget and the toolbar widgets. Therefore we had to do some extra work in the toolbar buttons to double check if the `DocumentController` and `HistoryController` are defined.