import 'dart:async';

import '../const/default-marker-type.const.dart';
import '../models/marker-type.model.dart';
import '../models/marker.model.dart';

// Before initialising the editor we need to provide a list of markers types
// that are available for insertion in the delta document.
// Controls also the visibility of every marker type.
class MarkersTypesState {
  final _toggleMarkersByTypes$ = StreamController<void>.broadcast();
  List<MarkerTypeM> markersTypes = [DEFAULT_MARKER_TYPE];
  List<String> invisibleMarkersIDs = [];

  Stream<void> get toggleMarkersByTypes$ => _toggleMarkersByTypes$.stream;

  void addMarkerType(MarkerTypeM type) {
    markersTypes.add(type);
  }

  void removeMarkerType(MarkerTypeM type) {
    markersTypes.remove(type);
  }

  void removeAllMarkersTypes() {
    markersTypes = [];
  }

  // === MARKER TEXT VISIBILITY ===

  // Shows/hides markers text by type.
  void toggleMarkerTextVisibilityByTypeId(
    String markerTypeId,
    bool isVisible,
  ) {
    final markerType = _getMarkerTypeById(markerTypeId);
    final markerTypeIndex = markersTypes.indexOf(markerType);

    markersTypes[markerTypeIndex] = markerType.copyWith(
      isTextVisible: isVisible,
    );

    // Used to trigger rendering. Marker types values are read sync.
    _toggleMarkersByTypes$.sink.add(null);
  }

  // Shows/hides text for a single marker.
  void toggleMarkerTextVisibilityByMarkerId(
    String markerId,
    bool isVisible,
  ) {
    if (isVisible) {
      if (invisibleMarkersIDs.contains(markerId)) {
        invisibleMarkersIDs.remove(markerId);
      }
    } else {
      if (!invisibleMarkersIDs.contains(markerId)) {
        invisibleMarkersIDs.add(markerId);
      }
    }

    // Used to trigger rendering. Marker types values are read sync.
    _toggleMarkersByTypes$.sink.add(null);
  }

  bool isMarkerTypeTextVisible(String markerTypeId) {
    final markerType = _getMarkerTypeById(markerTypeId);

    return markerType.isTextVisible;
  }

  // === MARKER HIGHLIGHT VISIBILITY ===

  // Shows/hides markers highlights by type.
  void toggleMarkerHighlightVisibilityByTypeId(
    String markerTypeId,
    bool isVisible,
  ) {
    final markerType = _getMarkerTypeById(markerTypeId);
    final markerTypeIndex = markersTypes.indexOf(markerType);

    markersTypes[markerTypeIndex] = markerType.copyWith(
      isHighlightVisible: isVisible,
    );

    // Used to trigger rendering. Marker types values are read sync.
    _toggleMarkersByTypes$.sink.add(null);
  }

  bool isMarkerTypeHighlightVisible(String markerTypeId) {
    final markerType = _getMarkerTypeById(markerTypeId);

    return markerType.isHighlightVisible;
  }

  // === PRIVATE ===

  MarkerTypeM _getMarkerTypeById(String markerTypeId) {
    return markersTypes.firstWhere((type) => type.id == markerTypeId);
  }
}
