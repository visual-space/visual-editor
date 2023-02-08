# State Store
Visual Editor has a lot of internal state to manage: the document, cursor position, text selection, the pressed keys, etc. One of the major changes since forking from Quill was to isolate all the state in a dedicated pure data layer. This change yields greatly improved code readability.

## Inherited Architecture
The original architecture inherited from [Quill](https://github.com/singerdmx/flutter-quill/issues) had several core issues:
- **Large Source Files** - First of all, many classes were hosted in the same file, some reaching 2K lines of code. Many classes hosted in the same file were reading each other's private states. Dart allows 2 classes in the same file to access private props between them. This practice leads to spaghetti code.
- **Classes were sharing scopes** - This issue stems from the architecture of Flutter. The `@override` methods required by Flutter to implement text editing influenced the early Quill/Zephyr implementation to share the scope of the editor widget with other classes. Again this created spaghetti code since the business object domains are not easy to recognise in the Quill codebase. 
- **Overreliance on ChangeNotifiers and Providers** - `ChangeNotifiers` are a convenient way of announcing other classes that a class changed it's state. This approach is convenient for a small app. However at the size of Quill (over 13K lines of code) this is no longer a suitable approach. Why? Because we are mixing data and methods in a bag and we are making it very hard to trace what does what. Even more annoying is the overuse of `Providers`. Because they pass data trough the widget tree it's even harder to trace from where to where this data travels. When you have 13K code, all tangled, it no longer is reasonable to use Notifiers and Providers as your state management solution.

All these issues together made Quill difficult and frustrating to extend. The source code should be easy to read and maintain, even for developers that are not familiar with the code base.

### Large Scopes
In the first stage of refactoring we did split the large files in modules and smaller files. The second part was to separate the state in a dedicated layer. The first major challenge was to split the editor class which had a scope that contained between 5-6K lines of code (main class + mixins). Most of the methods from these scopes knew each other and their states. This happened due to the many mixins that were implemented by Flutter. It forced the original authors to keep passing scopes around to achieve their goals.

When a project starts small it's easy to overlook state management concerns, relying only on ChangeNotifiers and Providers. This approach works ok for a while but it quickly becomes unbearable. In the case of Quill, nobody wanted to own the problem and everybody just patched "one more little thing" until leading to a major case of spaghetti code. 

## Improved Architecture
In essence, the editor code flow boils down to 2 steps: preparing the raw data to be processed and then calling the build method to update the UI. There are no widgets running in parallel consuming different data sources. Therefore, existing state store libs for single page apps are not suitable. Instead we developed a simple internal state store solution using basic Dart data classes and a stream to trigger the build cycle. The entire state management architecture follows these principles:

- **Global State** - The entire state of the app is stored in a global class that contains state objects for each feature.
- **Pure Data** - The goal is to keep only pure data classes in the state store. No data processing methods are hanging around. The code that manipulates the data should be isolated from the data itself.
- **Immutable** - Ideally we would have the entire codebase written in immutable classes. However due to the data format of the delta document and due to the data flow in editor (one giant build cycle) it's impractical to use only immutable objects. In places where it was possible we used immutable. However in many other places the stae store is mutable.
- **Unidirectional** - All the interactions that trigger state changes will trigger a build cycle. In the new build cycle, all the lines of text will check if their particular node of text has mutated. If so the `TextLine` will trigger internally a repaint. No TextLine can communicate to another TextLine directly. Neither the toolbar. Therefore the entire state store architecture is considered unidirectional.

## Editor Config
The first step towards implementing the new state store was migrating all the props from the `VisualEditor` constructor params into a dedicated model class `EditorConfigM`. Once separated, the model class was moved to a dedicated `EditorConfigState` class. This class is now available in the `EditorState` class.

**editor-config.model.dart**

```dart
@immutable
class EditorConfigM {
  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final bool autoFocus;
  // ...

  const EditorConfigM({
    this.scrollable = true,
    this.padding = EdgeInsets.zero,
    this.autoFocus = false,
    // ...
```

**editor-config.state.dart**

```dart
import '../models/editor-cfg.model.dart';

// The settings used by the client app to instantiate a Visual Editor.
class EditorConfigState {
  EditorConfigM _config = const EditorConfigM();
}
```

## Global State
All the states of the editor are stored together in one global object that is passed around.

```dart

class EditorState {
  final document = DocumentState();
  final editorConfig = EditorConfigState();
  // ...
}
```

## Project Structure
The source code is split in several module folders. Each module is dedicated to a major feature of the editor and each one contains a `/state` subfolder. Inside the `/state` subfolder we store a state class for each feature that needs to pass data around the code base.
```
/controller
/cursor
/documents
  /controllers
  /models
  /services
  /state
    document.state.dart
  /widgets
```

## Refreshing The Widget Tree
In a reactive state store management library all the relevant properties are passed around via observables subscriptions. Each subscription can trigger a distinct widget (or set of widgets) to update. Unlike a web app which has widgets that can update independently, the Visual Editor acts as one large page that updates all the lines and blocks of text in build cycle. 

There is only one stream that acts as a signal for all the classes and widgets to trigger an update: `runBuild$`. In the new build cycle, all the lines of text will check if their particular node of text has mutated. If so the `TextLine` will trigger internally a repaint. No TextLine can communicate to another TextLine directly. Neither the toolbar. Therefore the entire state store architecture is considered unidirectional.

```dart
// Emitting the build signal (for example when changing the text selection)
_state.runBuild.runBuild();

// Listening for the build signal
_runBuild$L = _editorService.getRunBuild$(widget._state).listen(
  (_) => {
    // ...  
  },
);

// Unsubscribing (when widgets are destroyed)
@override
void dispose() {
  _runBuild$L.cancel();
  super.dispose();
}
```

## Singletons vs Distinct Instances
There are many classes that need access to the state store: toolbar, editor, toolbar buttons. The first attempt to migrate the state architecture made use of singleton state classes. The advantage of importing singleton state classes was the elimination of drilling down props trough the call stack. However the state got shared between multiple running instances of the editor. 

The solution was to bundle all the state classes in a single `EditorState` class. The global state class gets instantiated once per `EditorController`. Therefore each editor instance has it's own internal state independent of the other editors from the same page. With the current pattern we still have to drill down props, but it's far easier to follow the line since all we pass around is the state store.

## Encapsulation
A major concern when designing the state store was to make sure that the state store is not exposed in the public. Encapsulating the state prevents developers from accessing/changing the internal state when writing client code. Preventing such practices enables the library source code to evolve without introducing breaking changes in the client code.

One extra challenge was dealing with synchronising the Toolbar buttons and the VisualEditor document. The extra difficulty comes from the fact that the buttons can be exported outside of the library to be used in a custom crafted toolbar. Therefore we need to be able to pass the `EditorState` from the `EditorController` without exposing the state store to the client app. 

To prevent direct access to the store we created a base class `EditorStateReceiver`. This class is implemented by any class that needs access in the state store (buttons, editor). When such a class receives the `EditorController` (as required) in the receiver class constructor the method `controller.setStateInEditorStateReceiver(this);` is invoked. This does the job of passing the state without ever exposing it in the public.

Beware, it's not recommended to access directly the state store in your client code (unless you know exactly what you are doing). When the internal editor architecture changes, you'll have to upgrade as well. Ideally make a PR or request us to expose in the public API the hooks you need.

```dart
class ColorButton extends StatefulWidget with EditorStateReceiver {
  final IconData icon;
  late EditorState _state;

  ColorButton({
    required this.icon,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
  }

  @override
  void cacheStateStore(EditorState state) {
    _state = state;
  }
```

Notice that not all classes that access the state store implement `EditorStateReceiver`. Only the ones that are publicly defined and are initialised with a reference of the controller. All other classes receive the state straight away int the constructor. For those classes which can be accessed from the public space we took care to cache the state internally in a private var.

```dart
void _cacheStateStore(EditorState state) {
  _state = state;
}

CursorController({required EditorState state,}) {
  _cacheStateStore(state);
}
```

## Internal References
One annoying issue that is still present is the need to access the scopes of widgets that implement the overrides requested by Flutter or the `FocusNode` or `ScrollController` that the user provides. To avoid creating more prop drilling these scopes are all cached in the state store in a dedicated `EditorReferences` class. Although storing these reference in the state store, infringes on the "pure data" principle we still implemented this trick because it reduces the amount of prop drilling required in the code.

```dart

// Global state
class EditorState {
  // ...
  
  // A dedicated branch for caching references to be passed around the codebase
  final refs = ReferencesState();
}

// All references needed in the source code
class ReferencesState {
  late EditorController _editorController; // Shared between the editor and the toolbar
  late ScrollController _scrollController;
  late CursorController _cursorController;
  late VisualEditor _editor; // widget containing Flutter overrides for text editing
  late VisualEditorState _editorState; // widget containing Flutter overrides for text editing
  late EditorRendererInner _renderer;
  late FocusNode _focusNode;
}

// Caching these states on init
VisualEditor({
  required this.controller,
  required this.scrollController,
  required this.focusNode,
  required this.config,
  Key? key,
}) : super(key: key) {
  controller.setStateInEditorStateReceiver(this);
    
  // Singleton caches.
  // Avoids prop drilling or Providers.
  // Easy to trace, easy to mock for testing.
  _state.refs.setEditorController(controller);
  _state.refs.setScrollController(scrollController);
  _state.refs.setFocusNode(focusNode);
  _state.editorConfig.setEditorConfig(config);
  _state.refs.setEditor(this);
}

// Accessing data or methods from the referenced scopes
final hasFocus = state.refs.focusNode.hasFocus;

```

## Disposing The Old CursorController Race Condition
This is a technical note explaining some difficulties we had with setting up the current state store. It's meant for lib architects that need to change the state store patterns. If you are not interested in the topic you can skip.

A complex set of circumstances led to the need of shallow cloning the state store. We created the state store to separate the state in a standalone layer instead of having it mixed in the code. We keep the state store in the controller because we can have multiple editors in the page (meaning we need multiple states). The state is passed to the VisualEditor and Toolbar via a safety mechanism that prevents external access to the state.

One of the issues that happens in this setup is that novice users can generate the controller in the template. It's possible that when the parent page triggers a build, the editor widget does not change, yet the controller is new. Therefore we have a few steps needed to disconnect the old controller and connect the new one (triggered via Flutter widget life cycle methods).

Another possible situation is that we are creating the controller only once but we trigger a new widget build. For example in the sandbox page we have a change of layout happening between mobile and desktop. This change of layout prompts Flutter to rebuild the editor using the old controller. During this widget rebuild process we are creating new instances of controllers such as the `CursorController`. The trouble is triggered by the fact that the old widget and the new widget use the same state instance. When the new controller is created it gets stored in the refs state of the old state store (same reference). Later once the old widget is disposed, the widget will also dispose of the newly created controller by mistake. Which creates a runtime error because we are trying to subscribe to ValueNotifier that no longer is active.

**Old Solution (dirty)**

The solution was to shallow clone the state such that the previous state module remain intact, except the references. The references module is created from scratch again. Thanks to this new setup we no longer store the new cursor controller in the state of the old widget. Which means we can safely dispose of the old cursor controller and keep using the new cursor controller.

**New Solution (clean)**
The previous solution proved to be a mistake. Since moving to the new pure models for document we moved everything in the `DocumentController`. When creating the `EditorController` we also init a `DocumentController` which then gets stored in state refs. However since we have the previous trick it gets deleted by the time it arrives to the toolbar. Why? Because each time we pass the state from controller to state receivers we did the shallow clone trick. But the trick itself causes the above described problem. So now we have to get rid of shallow cloning completely and keep the same old state instance alive between widget rebuilds. Instead we are going to keep 2 properties for the `CursorController`. One for the new and one for the old. Therefore we can prevent the old widget instance to command the new `CursorController` to close on widget destroy.

## Contributing
Any Pull Request that does not conform to the principles of this document and attempts to "patch" things quick and dirty will be rejected. If you need advice on how to contribute please join our live discord server where you can talk to the maintainers and receive advice on how to plan your bug fixes or new features. 

Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.