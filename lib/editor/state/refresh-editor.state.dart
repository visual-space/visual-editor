import 'dart:async';

// Updates the entire editor layout (widgets tree).
// Most of the state of the editor is read synchronous.
// This is the signal that triggers the sync reads.
// It's triggered by several text editing operations.
// Read more here: https://github.com/visual-space/visual-editor/blob/develop/lib/shared/state-store.md
class RefreshEditorState {
  final _refreshEditor$ = StreamController<void>.broadcast();

  Stream<void> get refreshEditor$ => _refreshEditor$.stream;

  void refreshEditor() {
    _refreshEditor$.sink.add(null);
  }
}
