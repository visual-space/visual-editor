import 'dart:async';

class CursorState {

  // === PAINT CURSOR ===

  // Triggers repaint for the cursor in a text line.
  final _paintCursor$ = StreamController<void>.broadcast();

  Stream<void> get paintCursor$ => _paintCursor$.stream;

  void paintCursor() {
    _paintCursor$.sink.add(null);
  }

  // === SCHEDULE ===

  // Since the caret needs the latest layout to animate we need to schedule a post build callback.
  // To avoid triggering multiple such callbacks we use this variable as a locking mechanism.
  bool showCaretOnScreenScheduled = false;
}
