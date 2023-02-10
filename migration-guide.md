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
    autoFocus: false,
    readOnly: false,
    placeholder: 'Add content',
    expands: false,
    padding: EdgeInsets.zero,
    customStyles: DefaultStyles(
      h1: TextBlockStyleM(
        const TextStyle(
          fontSize: 32,
          color: Colors.black,
          height: 1.15,
          fontWeight: FontWeight.w300,
        ),
        const Tuple2(16, 0),
        const Tuple2(0, 0),
        null
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
      customStyles: DefaultStyles(
        h1: TextBlockStyleM(
          const TextStyle(
            fontSize: 32,
            color: Colors.black,
            height: 1.15,
            fontWeight: FontWeight.w300,
          ),
          VerticalSpacing(top: 16, bottom: 0),
          VerticalSpacing(top: 0, bottom: 0),
          null,
        ),
        sizeSmall: const TextStyle(fontSize: 9),
      ),
    ),
  );
  // ...
}
```

- **showCursor was removed** - The caret is no longer displayed in readonly mode. The `showCursor` configuration option for `VisualEditor` was removed. It makes no sense to have the cared showing up in readonly mode. Or the caret missing in editable mode.
- **Removed child builders for toolbar buttons** - We removed `defaultToggleStyleButtonBuilder` from `ToggleStyleButton` and from `ToggleCheckListButton` because we already provide the option to create a custom toolbar from scratch using the toolbar buttons in a custom order. Having two ways to override the buttons is overkill.
- **Moved keepStyleOnNewLine to Editor Config** - Moved `keepStyleOnNewLine` from the controller to the state store in `EditorConfigM`. There was no need to separate this property from the main config.


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

