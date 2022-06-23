import 'dart:async';

// Triggers repaint for the cursor in a text line.
class CursorState {
  factory CursorState() => _instance;
  static final _instance = CursorState._privateConstructor();

  CursorState._privateConstructor();

  final _updateCursor$ = StreamController<void>.broadcast();

  Stream<void> get updateCursor$ => _updateCursor$.stream;

  void updateCursor() {
    _updateCursor$.sink.add(null);
  }
}
