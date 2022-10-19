import 'dart:async';

// Despite being part of the delta document the markers can be hidden on demand.
// Toggling markers from the editor controller can be useful for situations where the developers want
// to clear the text of any visual guides and show the pure rich text.
class MarkersVisibilityState {
  bool _visibility = true;

  bool get visibility => _visibility;

  // Used to trigger markForPaint() in EditableTextLineRenderer (similar to how the cursor updates it's animated opacity).
  // We can't use _state.refreshEditor.refreshEditor() because there's no new content,
  // Therefore Flutter change detection will not find any change, so it wont trigger any repaint.
  final _toggleMarkers$ = StreamController<void>.broadcast();

  Stream<void> get toggleMarkers$ => _toggleMarkers$.stream;

  void toggleMarkers(bool areVisible) {
    _toggleMarkers$.sink.add(null);
    _visibility = areVisible;
  }
}
