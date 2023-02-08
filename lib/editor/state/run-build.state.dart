import 'dart:async';

// Updates the entire editor layout (widgets tree) by triggering a build() cycle.
// The entire editor life cycle is separated in 2 major stages:
// - Updating the document
// - Rendering the latest doc changes as widgets
// All operations that need to apply a visible change in the widget tree will trigger this stream.
// This is one of the very few streams in the editor.
// Anything else is read asynchronously from the state store during a build() cycle.
// Read more: state-store.md
class RunBuildState {
  final _runBuild$ = StreamController<void>.broadcast();

  Stream<void> get runBuild$ => _runBuild$.stream;
  bool ignoreFocusOnTextChange = false;

  // After changes have been made to the document state
  // now we are triggering a new build() cycle.
  void runBuild() {
    _runBuild$.sink.add(null);
  }

  // Temporary disable the placement of the caret when changing text.
  // This prevents annoying behavior such as triggering the caret when hovering the highlights.
  void runBuildWithoutCaretPlacement() {
    ignoreFocusOnTextChange = true;

    runBuild();

    // We have to wait for the above async task to complete.
    // The easiest way is to place a Timer with Duration 0 such that the immediate
    // next task after the async code is to reset the temporary override.
    Timer(Duration.zero, () {
      ignoreFocusOnTextChange = false;
    });
  }
}
