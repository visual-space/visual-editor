# State Store
Visual Editor has a lot of state to deal with internally, ranging from the contents of the document, position of the cursor and text selection down to pressed keys and the last tap location. Dealing with this state is quite a challenge. I made a great effort to refactor the state management architecture to a form that is way easier to understand and to extend. It's not a perfect solution, it has it's own drawbacks, however it yields greatly improved code readability. The simple fact that all the state is isolated by modules and features gives you an Xray of the entire codebase to better understand what are the major features at play. But first let's start with some backstory.

**(!) Ongoing Effort** - Keep in mind that the code base is still under refactoring since it was forked from Quill. It's still evolving so you will still find places where the above principles are not fully enforced. 

## Inherited Architecture
The original architecture inherited from [Quill](https://github.com/singerdmx/flutter-quill/issues) had several core issues:
- **Large Source Files** - First of all, many classes were collocated in the same file in multiple files, some of them reaching 2K lines of code. This was made even worse by the fact that in many places classes from the same file were reading each other's private states. Dart allows 2 classes in the same file to access private props between them.
- **Classes were sharing scopes** - This issue stems from the architecture of Flutter. Flutter provides a large number of overrides and mixins to be implemented when dealing with text. These `@override` methods "influenced/forced" the early architecture to pass the scope of the editor widget state (an several other) all over the place trough the code base. (I'm using quotes because there's always a nice way if you take your time and care enough about it).
- **Overreliance on ChangeNotifiers and Providers** - `ChangeNotifiers` are a convenient way of announcing other classes that a class changed it's state. This is nice and convenient when dealing with a small app. However at the size of Quill (over 13K lines of code) this is no longer a suitable approach. Why? Because we are mixing data and methods in a bag and we are making it very hard to trace what does what. Even more annoying is the overuse of `Providers`. Because they pass data trough the widget tree it's even harder to trace from where to where this data travels. I know it sounds like a simple to understand mechanism, but when you have 13K code all tangled in spaghetti code it no longer is.

All these issues added together made dealing with changes in Quill a major source of pain. It took me more than 2 months and a full refactoring of Quill to get to a point where I feel comfortable making changes in the code. This does not need to be this way. I believe source code should be easy to read and maintain. It should have conventions that make it easy to extend without producing chaos, and extending it should be an overall pleasant experience. Even if that means learning from scratch how a Rich Text Editor works.

### Large Scopes
After the first stage of the refactoring was completed (splitting in modules and files) the second part was to deal with the way state was passed around. A major problem was that one of the classes had a scope that contained between 5-6K lines of code. Most of the methods from these scopes knew each other and their states. This happened due to the many mixins that were implemented by Flutter. It forced the original authors to keep passing scopes around to achieve their goals.

### Excessive Technical Debt
Usually when a project starts small it's easy to say that a state management solution is overkill and we are fine by just passing state around either by ChangeNotifiers, passing scopes or via Flutter Providers. This works fine until it no longer can be bearable. In the case of Quill it kept growing relying on contributions from maintainers desperate enough to need changes in the code base. The major mistake here was not identifying the problem and not acting on it. Nobody wanted to own the problem and everybody just patched "one more little thing" until the thing became the "The Flying Spaghetti Monster" himself. Moral of the story: don't treat technical debt as an externality that someone else has to deal with. Do your homeworks early.

## Improved Architecture
The new state store architecture follows established practices from modern front end state management libraries. Using an existing state store management framework was not an option due to the anatomy of Quill. Therefore, a simple state store solution, tuned to the needs of the editor using basic Dart language features was developer on the go. The entire state management architecture follows these principles:

- **Pure Data** - The goal is to keep only pure data classes in the state store. No utils methods are hanging around. The code that manipulates "the data" should be isolated from "the data" itself. At the moment there are still places where some methods are present in the state store. As new features are added more state store cleanups will be done. 
- **Immutable** - Many of the state store model classes are in the process of being converted into immutable objects. The goal is to avoid making direct changes on references received from the state store. The state store itself can be updated but not the contents of the objects stored inside.
- **Global State** - The entire state of the app is stored in a global class that contains all the state split in modules and features. Before rushing to say "global is evil" keep in mind that as long as you have clear rules on how to deal with changes in the state, this is quite a beneficial pattern. It greatly reduces the amount of properties that are passed around via prop drilling.
- **Unidirectional** - Traversing up and down the widget tree to pass the data from the widgets that produce it to the widgets that consume it should be avoided. All the updates should be passed trough the state store and then the consumers should receive/read the updated data from the state store.

## Editor Config
The first step towards implementing the new state store was migrating all the props from the `VisualEditor` constructor params into a dedicated model class `EditorConfigM`. Once separated, the model class was moved to a dedicated `EditorConfigState` class. This class is now available in the `EditorState` class.

**editor-config.model.dart**

```dart
// Truncated version
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

// These are the settings used by the client app to instantiate a Visual Editor.
class EditorConfigState {
  EditorConfigM _config = const EditorConfigM();

  EditorConfigM get config => _config;

  void setEditorConfig(EditorConfigM config) => _config = config;
}
```

## Global State
All the states of the editor are stored together in one global object that is passed around.

```dart

class EditorState {
  // Documents
  final document = DocumentState();

  // Editor
  final editorConfig = EditorConfigState();
  final refreshEditor = RefreshEditorState();
  final platformStyles = PlatformStylesState();
  final scrollAnimation = ScrollAnimationState();

  // ...
}

```

## Project Structure
The soruce code is split in several module folders. Each module is dedicated to a major feature of the editor and each one contains a `/state` subfolder. Inside the `/state` subfolder we store a state class for each feature that needs to pass data around the code base.
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
In a reactive state store management library all the relevant properties are passed around via observables subscriptions. Each subscription can trigger a distinct widget (or set of wdigets) to update. Unlike a web app which has predefined widgets that can update independently, the Visual Editor acts as a whole unit that updates all the lines and blocks of text at once. Obviously the change detection in Flutter plays a great role by not triggering updates in the `TextLine` or `TextBlock` widgets that did not change. 

There is only one stream that acts as a signal for all the classes and widgets to trigger an update: `updateEditor$`. Once this signal emits everything else downstream will read its corresponding state in a sync fashion. Meaning that each feature reads directly from the state store instead of waiting for a subscription. Keep in mind that unlike a web app which has a fixed known layout the text editor can have N layouts all with unexpected combinations. So basically it's not feasible to have dedicated subscriptions per dedicated object types. Everything can be updated at once as a consequence of triggering the document state.

```dart
// Emitting an update signal (for example when changing the text selection)
_state.refreshEditor.refreshEditor();

// Listening for the update signal
_refreshListener = widget._state.refreshEditor.updateEditor$.listen(
  (_) => _didChangeEditingValue,
);

// Unsubscribing (when widgets are destroyed)
@override
void dispose() {
  _refreshListener.cancel();
  super.dispose();
}
```

## Encapsulation
A major concern when designing the state store was to make sure that the state store is not exposed in the public. Encapsulating the state prevents developers from accessing/changing the internal state when writing client code. Preventing such practices enables the library source code to evolve  without introducing breaking changes in the client code.

There are many classes that need the state to be passed around. An additional challenge is that we need multiple state store, one per `EditorController` instance. Otherwise we end up having several editors in the same page that share the same state. The first attempt to migrate the state architecture made use of singleton classes to store the state per features. However once complete the issue of sharing states between running instances showed up. The solution was to bundle all the state classes in a single `EditorState` class. This class gets instantiated once per `EditorController`. Therefore each editor instance has it's own internal state independent of the other editors from the same page.

**Passing State**

Methods hosted in services receive the state via params. As explained above we can't inject in services the state if we want multiple editors on the same page. So some amount of prop drilling is present in the code base. However for widgets the things are looking better. We pass to the widgets/controllers/renderers the editor state via the constructor's params. A public-write-only setter is used to prevent access to the state from the outside.

```dart
class ColorButton extends StatefulWidget with EditorStateReceiver {
  late EditorState _state;

  @override
  void setState(EditorState state) {
    _state = state;
  }
```

**Passing Same State to Multiple Widgets**

One extra challenge was dealing with synchronising the Toolbar buttons and the VisualEditor document. The extra difficulty comes from the fact that the buttons can be exported outside of the library to be used in a custom crafted toolbar. Therefore we need to be able to pass the `EditorState` from the `EditorController` without involving the client developer. The abstract class `EditorStateReceiver` is implemented by any class that needs access in the state store (buttons, editor). When such a class receives the `EditorController` (as required) in the receiver class constructor the method `controller.setStateInEditorStateReceiver(this);` is invoked. This does the job of passing the state without ever exposing it in the public.

```dart
class ColorButton extends StatefulWidget with EditorStateReceiver {
  final IconData icon;
  // ...

  late EditorState _state;

  @override
  void setState(EditorState state) {
    _state = state;
  }

  ColorButton({
    required this.icon,
    // ...
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
  }
```

## Scopes References
One annoying issue that is still present is the need to access the scopes of widgets that implement the overrides requested by Flutter or the `FocusNode` or `ScrollController` that the user provides. To avoid creating more prop drilling these scopes are all cached in the state store in a dedicated `EditorReferences` class. This infringes on the "pure data" principle. 

Given the constraints explained above such as: multiple instances and Flutter overrides, I find this an acceptable solution. Sometimes straying away from dogmatic fundamentals can yield great results as long as there is a clear plan and process behind het architecture. As long as the state store needs are clearly communicated, multiple contributors should be able to work hassle free in the same codebase.

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

## Contributing
Any Pull Request that does not conform to the principles of this document and attempts to "patch" things quick and dirty will be rejected. If you need advice on how to contribute please join our live discord server where you can talk to the maintainers and receive advice on how to plan your bug fixes or new features. 

Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.