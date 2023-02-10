# Editor 
This is the main class of the Visual Editor. The editor can start completely on default values. The editor can be rendered either in scrollable mode or in expanded mode. Most apps will prefer the scrollable mode and a sticky EditorToolbar on top or at the bottom of the viewport. Use the expanded version when you want to stack multiple editors on top of each other. A placeholder text can be defined to be displayed when the editor has no contents. All the styles of the editor can be overridden using custom styles. Each instance of the editor will need an `EditorController`. EditorToolbar can be synced to `VisualEditor` via the `EditorController`.


## Architecture
As you probably observed, the `main.dart` file is the editor widget itself. We named the file main to give new contributors a clear indication where to start reading the codebase. Under normal circumstance this file should be listed at the root of the editor module. But since it serves also as the main entry in the code base we chose to list it at the root of the `/lib` folder.

Several major improvements have been made since forking from Quill. First of all the build() method has been cleaned and shrunk down from 200 LOC to around 20. It's a lot easier to understand what the editor widget is composed of. In fact, the `build()` it's simply a long series of nested widgets, like the onion layers. Each one of these widgets ads one more feature on top of the editor. At the end of it we have the document tree, which is just the collection of text lines. One additional improvement was to get rid of the `Editor` and `RawEditor` distinction by merging them in one single widget. These two components have little to no reason to be separated as they are currently in the Quill codebase.

The main widget implements several mixins as provided by the Flutter architecture. These mixins are absolutely essential for managing custom fields inside the Flutter framework. This overrides architecture is highly OOP oriented. Since we were forced to implement these overrides in the main class an additional challenge was somehow isolating the state from the main class. I highly recommend a read trough the [State Store](https://github.com/visual-space/visual-editor/blob/develop/lib/shared/state-store.md). 


## Editor Config Model
When instantiating a new Visual Editor, developers can control several styling and behaviour options. They are all defined here in this model for the sake of clear separation of code. By eliminating individual properties from the main VisualEditor instance and grouping them in a model. we create a far easier to read and maintain architecture. Grouping these properties in a class makes passing these properties around a lot easier. Note that the editor and scroll controllers are passed at the top level not here in the config. 


## Services
- **EditorService** - Contains the logic that orchestrates the editor UI systems with the `DocumentController` (pure data editing). Does not contain the document mutation logic. It delegates this logic to the `DocumentController`.
  - Updates all systems of the editor (selection, focus, scroll, markers, menus, etc).
  - Invokes the callbacks provided by the client code.
  - Triggers the build cycle.
  - Relays the document editing commands to the `DocumentController`
- **GuiService** - After document model was updated this service updates the text GUI right before triggering the build. Requests the soft keyboard. Handles web and mobiles. Updates the remote value in the connected system input. Displays the caret on screen and prevents blinking while typing. Triggers the build cycle for the editor and the toolbar. Shows, hides selection controls after the build completed.
- **RunBuildService** - Provides easy access to the build trigger. After the document changes have been applied and the gui elements have been updated, it's now time to update the document widget tree.





