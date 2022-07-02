import 'editor.state.dart';

// We need a way to pass the editor state from the EditorController instance to the buttons without exposing it in public.
// We don't want to expose the editor state in public because we don't want developers
// to write code that depends on library internals.
// Additionally we want to export all the buttons of the Toolbar enabling the developers
// to init the Toolbar with a custom set of buttons ordered arbitrarily.
// This means we can't expect client developers to init the state of the buttons.
// That would break the encapsulation principle for the editor state.
// Therefore passing the state from VisualController to the toolbar buttons has to be done "behind the scenes".
// The method bellow enables the controller to feed the state in the buttons
// without exposing the state in either of the scopes.
// By creating this abstract class we ensure that the EditorController can pass the state only to EditorStateReceivers (buttons).
// Therefore direct reckless access to the state is secured without completely eliminating the possibility of passing the state.
abstract class EditorStateReceiver {
  void setState(EditorState state);
}
