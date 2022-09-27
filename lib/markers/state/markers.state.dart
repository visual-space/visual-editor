import '../models/marker.model.dart';

class MarkersState {
  List<MarkerM> _markers = [];

  List<MarkerM> get markers => _markers;

  // TODO Replace this system with a post build get all markers and rectangles
  // We need to collect all markers from all lines only once per document update.
  // Subsequent draw calls that are triggered by the cursor animation will be ignored.
  var cacheMarkersAfterBuild = false;

  void setMarkers(List<MarkerM> markers) {
    _markers = markers;
  }

  void addMarker(MarkerM marker) {
    _markers.add(marker);
  }

  void removeMarker(MarkerM marker) {
    _markers.remove(marker);
  }

  void removeAllMarkers() {
    _markers = [];
  }
}
