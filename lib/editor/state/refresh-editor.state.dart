import 'dart:async';

// Updates the entire editor layout (widgets tree) by triggerin a build() cycle.
// The entire editor life cycle is separated in 2 major stages:
// - Updating the document
// - Rendering the latest doc changes as widgets
// All operations that need to apply a visible change in the widget tree will trigger this stream.
// This is one of the few streams of data that command the widgets tree.
// Anything else is read asynchronously from the state store during a build() cycle.
// Read more here: https://github.com/visual-space/visual-editor/blob/develop/lib/shared/state-store.md
class RefreshEditorState {
  final _refreshEditor$ = StreamController<void>.broadcast();

  Stream<void> get refreshEditor$ => _refreshEditor$.stream;
  bool ignoreFocusOnTextChange = false;

  // After the desired changes have been made to the document now we are triggering a new build() cycle
  // to render the widgets in the state dictated by the document.
  void refreshEditor() {
    _refreshEditor$.sink.add(null);
  }

  // Temporary disable the placement of the caret when changing text.
  // This prevents annoying behavior such as triggering the caret when hovering the highlights.
  void refreshEditorWithoutCaretPlacement() {
    ignoreFocusOnTextChange = true;

    refreshEditor();

    // We have to wait for the above async task to complete.
    // The easiest way is to place a Timer with Duration 0 such that the immediate
    // next task after the async code is to reset the temporary override.
    Timer(Duration.zero, () {
      ignoreFocusOnTextChange = false;
    });
  }
}
