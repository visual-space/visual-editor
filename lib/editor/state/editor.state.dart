import 'dart:async';

class EditorState {
  factory EditorState() => _instance;
  static final _instance = EditorState._privateConstructor();

  EditorState._privateConstructor();

  final _updateEditor$ = StreamController<void>.broadcast();

  Stream<void> get updateEditor$ => _updateEditor$.stream;

  void refreshEditor() {
    _updateEditor$.sink.add(null);
  }
}
