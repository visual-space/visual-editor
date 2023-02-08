import 'package:collection/collection.dart';

import '../models/marker.model.dart';

// Unlike the other states the markers state is different, we don't use it as the source of truth.
// It's contents are derived from the structure of the delta document (it's a projection of the document).
// This cache is used for convenience here to help with the rendering of markers in text.
// This means we can't add a marker here and expect to see it in the delta document.
// For this to happen we need to use controller.addMarker().
// (!) Derived from the document at each build (not the source of truth)
class MarkersState {
  List<MarkerM> _markers = [];

  List<MarkerM> get markers => _markers;

  void cacheMarkers(List<MarkerM> markers) {
    _markers = markers;
  }

  void cacheMarker(MarkerM marker) {
    _markers.add(marker);
  }

  void flushMarker(MarkerM marker) {
    _markers.remove(marker);
  }

  void flushAllMarkers() {
    _markers = [];
  }

  // === HOVERED MARKERS ===

  final List<MarkerM> _hoveredMarkers = [];

  List<MarkerM> get hoveredMarkers => _hoveredMarkers;

  // Pointer has entered one of the rectangles of a marker
  void enterMarkerById(String id) {
    final marker = _markers.firstWhereOrNull(
      (marker) => marker.id == id,
    );

    if (marker != null) {
      _hoveredMarkers.add(marker);
    }
  }

  // Pointer has exited the rectangles of a marker
  void exitMarkerById(String id) {
    final marker = _hoveredMarkers.firstWhereOrNull(
      (marker) => marker.id == id,
    );

    if (marker != null) {
      _hoveredMarkers.remove(marker);
    }
  }
}
