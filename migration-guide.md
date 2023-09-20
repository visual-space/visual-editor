# Migrating from Quill
Visual Editor is a fork of Flutter Quill. The main reason we separated from Quill was the opaque architecture. We needed an easy to maintain code base, however the architecture of Quill made it really hard to follow the code flow and adding improvements was difficult at best. Therefore we decided to completely refactor the general architecture of Quill and reorganise it into modules, services, states and models. Due to these changes if you desire to migrate from Flutter Quill to Visual Editor.


- **Feedback Requested** - If you encounter any difficulties during the migration please start a new ticket. We will attempt to respond to your query and update this doc accordingly.
- **Backwards Compatibility** - Most of the features present in Flutter Quill have been preserved. However in time Visual Editor is expected to drift. At the moment the migration process is rather easy to follow. However we can't guarantee this for the long run. Changes over the years might make the two versions incompatible.


## Update Imports
If you are using a decent IDE you should be able to autoimport the required files by using the context menu or pressing the autoimport hotkey.
- Before: - `import 'package:flutter_quill/flutter_quill.dart';`
- After: - `import 'package:visual_editor/visual-editor.dart';`

Note that we renamed the `Text` class so we will no longer collides with the Text class from Flutter.


## Renamed Classes
Most of the top classes have been renamed to better reflect the new architecture.
- `QuillEditor` - `VisualEditor`
- `QuillController` - `EditorController`
- `QuillToolbar` - `EditorToolbar`
- `DefaultTextBlockStyle` - `TextBlockStyleM`
- `DefaultStyles` - `EditorStylesM`


## Editor Configuration
The migration of models includes also the properties of the VisualEditor. They are now separated to a distinct model `EditorConfigM`. We made this choice to facilitate the transport of the config properties trough the codebase a lot easier.

```dart
Widget _buildWelcomeEditor(BuildContext context) {
  var quillEditor = QuillEditor(
    controller: _controller!,
    scrollController: _scrollController,
    scrollable: true,
    focusNode: _focusNode,
    enableSelectionToolbar: true,
    autoFocus: false,
    readOnly: false,
    placeholder: 'Add content',
    expands: false,
    padding: EdgeInsets.zero,
    customStyles: DefaultStyles(
      h1: DefaultTextBlockStyle(
        const TextStyle(
          fontSize: 32,
          color: Colors.black,
          height: 1.15,
          fontWeight: FontWeight.w300,
        ),
        const VerticalSpacing(16, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      sizeSmall: const TextStyle(fontSize: 9),
    ),
  );
  // ...
}
```

Now becomes:
```dart
Widget _buildWelcomeEditor(BuildContext context) {
  var visualEditor = VisualEditor(
    controller: _controller!,
    scrollController: _scrollController,
    focusNode: _focusNode,
    config: EditorConfigM(
      placeholder: 'Add doc-tree',
      enableInteractiveSelection: false,
      autoFocus: false,
      readOnly: false,
      placeholder: 'Add content',
      expands: false,
      padding: EdgeInsets.zero,
      customStyles: EditorStylesM(
        h1: TextBlockStyleM(
          const TextStyle(
            fontSize: 32,
            color: Colors.black,
            height: 1.15,
            fontWeight: FontWeight.w300,
          ),
          VerticalSpacing(top: 16, bottom: 0),
          VerticalSpacing(top: 0, bottom: 0),
          VerticalSpacing(top: 16, bottom: 0),
          null,
        ),
        sizeSmall: const TextStyle(fontSize: 9),
      ),
    ),
  );
  // ...
}
```

- **`showCursor` was removed** - The caret is no longer displayed in readonly mode. The `showCursor` configuration option for `VisualEditor` was removed. It makes no sense to have the caret showing up in readonly mode. Or the caret missing in editable mode.
- **Removed `child` builders for toolbar buttons** - We removed `defaultToggleStyleButtonBuilder` from `ToggleStyleButton` and from `ToggleCheckListButton` because we already provide the option to create a custom toolbar from scratch using the toolbar buttons in a custom order. Having two ways to override the buttons is overkill.
- **Moved `keepStyleOnNewLine` to Editor Config** - Moved `keepStyleOnNewLine` from the controller to the state store in `EditorConfigM`. There was no need to separate this property from the main config.
- **`TextBlockStyleM` has an additional parameter** - When configuring `TextBlockStyle`, you will need to define 4 arguments, instead of 3. The added argument pertains to `lastLineSpacing`, the spacing at the end of the text block.
- **`enableSelectionToolbar` becomes `enableInteractiveSelection`**.

> [!WARNING]
>
> The `subscript` and `superscript` parameters in `DefaultStyles` are not yet available.

## Model Classes Suffix
During the refactoring we decided to move all the model classes in distinct `/models` folders. All model classes now use the M suffix to indicate they are a model classes. This convention is similar to how Java suffixes interfaces with I.
- `Document` - `DeltaDocM`
- `Operation` - `OperationM`


## Callbacks
**Moved callbacks from controller to Editor** - The following callbacks have been moved from the controller to the editor. Thanks to the lates architecture changes, we are no longer constrained to call in the controller methods defined only in the controller.

- `onReplaceText()`,
- `onDelete()`,
- `onSelectionCompleted()`,
- `onSelectionChanged()`,


## Toolbar Configuration


- `customIcons` becomes `customButtons` - We've renamed the property to better express it's purpose. When reading custom icons, it could be understood as giving the ability to replace the icon set on the existing buttons.
- `toolbarSectionSpacing` becomes `buttonsSpacing` - It suggested that it applies only to groups of buttons when in fact it applies to buttons and groups. Possibly this behavior will be reviewed to give better control on button and section spacings by adding a new property `sectionSpacing`.
- `EditorCustomIcon` becomes `EditorCustomButton` - Icons mean static images. Buttons indicate also a reaction when tapping.
- callbacks like `webImagePickImpl`, `mediaPickSettingSelector` and `onImagePickCallback` are **defined inside the buttons you can add to the toolbar in the `children` or `customButtons` fields** (`ImageButton`, `VideoButton` and `CameraButton`).


### Defining buttons for your toolbar

You may be using `QuillToolbar.basic` to define your toolbar. This will add all the buttons for you with minimal setup (even though you can customize which buttons you want to show). 
You can do the same thing with **`EditorToolbar.basic`**.

However, if you are *not using the `.basic` function*, you will need to add the buttons yourself. 
With `flutter-quill`, you may be using `FlutterQuillEmbeds.buttons` for this and appending this to the toolbar's `children`. 

**This is not the case in `visual-editor`**.

You will simply list the buttons in the `customButton` field and add the necessary callbacks (like `webImagePickImpl` or `onImagePickCallback`, for example) to the relevant buttons. You can also use the `children` field to enforce a custom order, feeding the list straight to `EditorToolbar`'s constructor. However, in this case, it's almost pointless to use this field as it does not provide much functionality on top of the customs buttons set.

Here's an example of how the toolbar definition would different. We'll be using the `children` field to add our buttons, just like we used to in `flutter-quill`.

This is how you do it in `flutter-quill`.

```dart
    // Toolbar definitions
    const toolbarIconSize = 18.0;
    final embedButtons = FlutterQuillEmbeds.buttons(
      // Showing only necessary default buttons
      showCameraButton: false,
      showFormulaButton: false,
      showVideoButton: false,
      showImageButton: true,

      // `onImagePickCallback` is called after image is picked on mobile platforms
      onImagePickCallback: _onImagePickCallback,

      // `webImagePickImpl` is called after image is picked on the web 
      webImagePickImpl: _webImagePickImpl,

      // defining the selector (we only want to open the gallery whenever the person wants to upload an image)
      mediaPickSettingSelector: (context) {
        return Future.value(MediaPickSetting.Gallery);
      },
    );

    // Instantiating the toolbar
    final toolbar = EditorToolbar(    
      afterButtonPressed: _focusNode.requestFocus,
      children: [
        HistoryButton(
          buttonsSpacing: toolbarButtonSpacing,
          icon: Icons.undo_outlined,
          iconSize: toolbarIconSize,
          controller: _controller!,
          isUndo: true,
        ),
        HistoryButton(
          icon: Icons.redo_outlined,
          iconSize: toolbarIconSize,
          controller: _controller!,
          undo: false,
        ),
        ToggleStyleButton(
          attribute: Attribute.bold,
          icon: Icons.format_bold,
          iconSize: toolbarIconSize,
          controller: _controller!,
        ),
        ToggleStyleButton(
          attribute: Attribute.italic,
          icon: Icons.format_italic,
          iconSize: toolbarIconSize,
          controller: _controller!,
        ),
        ToggleStyleButton(
          attribute: Attribute.underline,
          icon: Icons.format_underline,
          iconSize: toolbarIconSize,
          controller: _controller!,
        ),
        ToggleStyleButton(
          attribute: Attribute.strikeThrough,
          icon: Icons.format_strikethrough,
          iconSize: toolbarIconSize,
          controller: _controller!,
        ),
        for (final builder in embedButtons) builder(_controller!, toolbarIconSize, null, null),
      ],
    );
```

And this is how'd you do it in `visual-editor`.

```dart

    // Toolbar definitions
    const toolbarIconSize = 18.0;
    const toolbarButtonSpacing = 2.5;

    // Instantiating the toolbar
    final toolbar = EditorToolbar(          
      children: [
        HistoryButton(
          buttonsSpacing: toolbarButtonSpacing,
          icon: Icons.undo_outlined,
          iconSize: toolbarIconSize,
          controller: _controller!,
          isUndo: true,
        ),
        HistoryButton(
          buttonsSpacing: toolbarButtonSpacing,
          icon: Icons.redo_outlined,
          iconSize: toolbarIconSize,
          controller: _controller!,
          isUndo: false,
        ),
        ToggleStyleButton(
          buttonsSpacing: toolbarButtonSpacing,
          attribute: AttributesM.bold,
          icon: Icons.format_bold,
          iconSize: toolbarIconSize,
          controller: _controller!,
        ),
        ToggleStyleButton(
          buttonsSpacing: toolbarButtonSpacing,
          attribute: AttributesM.italic,
          icon: Icons.format_italic,
          iconSize: toolbarIconSize,
          controller: _controller!,
        ),
        ToggleStyleButton(
          buttonsSpacing: toolbarButtonSpacing,
          attribute: AttributesM.underline,
          icon: Icons.format_underline,
          iconSize: toolbarIconSize,
          controller: _controller!,
        ),
        ToggleStyleButton(
          buttonsSpacing: toolbarButtonSpacing,
          attribute: AttributesM.strikeThrough,
          icon: Icons.format_strikethrough,
          iconSize: toolbarIconSize,
          controller: _controller!,
        ),

        // Our embed buttons
        ImageButton(
            icon: Icons.image,
            iconSize: toolbarIconSize,
            buttonsSpacing: toolbarButtonSpacing,
            controller: _controller!,
            onImagePickCallback: _onImagePickCallback,
            webImagePickImpl: _webImagePickImpl,
            mediaPickSettingSelector: (context) {
              return Future.value(MediaPickSettingE.Gallery);
            },
        )
      ],
    );
```

Here's a list of relevant changes we've made:

- **removed `FlutterQuillEmbeds.buttons`** - we don't need to use `FlutterQuillEmbeds` to create embed buttons any more. We simply create them normally in the `children` field.
- **removed the `afterButtonPressed` field from `EditorToolbar` constructor**.
- **added `buttonsSpacing` field to all buttons**, as it's required.
- **`Attribute`** is now renamed to **`AttributesM`**.
- **`MediaPickSetting` is now renamed to `MediaPickSettingE`**.