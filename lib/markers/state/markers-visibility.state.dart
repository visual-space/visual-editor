import 'dart:async';

// Despite being part of the delta document the markers can be hidden on demand.
// Markers can be hidden by types or all in the same time.
// We can toggle more types at the same time.
// Toggling markers from the editor controller can be useful for situations where the developers want
// to clear the text of any visual guides and show the pure rich text.
class MarkersVisibilityState {
  bool _visibility = true;

  bool get visibility => _visibility;

  List<String> hiddenMarkersTypes = [];

  // Used to trigger markForPaint() in EditableTextLineRenderer (similar to how the cursor updates it's animated opacity).
  // We can't use _state.refreshEditor.refreshEditor() because there's no new content,
  // Therefore Flutter change detection will not find any change, so it wont trigger any repaint.
  final _toggleMarkers$ = StreamController<void>.broadcast();

  Stream<void> get toggleMarkers$ => _toggleMarkers$.stream;

  void toggleMarkers(bool areVisible) {
    _toggleMarkers$.sink.add(null);
    _visibility = areVisible;
  }

  bool isMarkerTypeVisible(String markerType) {
    var isVisible = true;

    if (hiddenMarkersTypes.contains(markerType)) {
      isVisible = false;
    }

    return isVisible;
  }

  void toggleMarkerByType(
    String markerType,
    bool isVisible,
  ) {
    _toggleMarkers$.sink.add(null);

    final isHidden = hiddenMarkersTypes.contains(markerType);

    if (isHidden && isVisible) {
      hiddenMarkersTypes.remove(markerType);
    }

    if (!isHidden && !isVisible) {
      hiddenMarkersTypes.add(markerType);
    }
  }
}
