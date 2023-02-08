import 'dart:async';

import '../const/default-marker-type.const.dart';
import '../models/marker-type.model.dart';

// Before initialising the editor we need to provide a list of markers types
// that are available for insertion in the delta document.
// Controls also the visibility of every marker type.
class MarkersTypesState {
  final _toggleMarkersByTypes$ = StreamController<void>.broadcast();
  List<MarkerTypeM> markersTypes = [DEFAULT_MARKER_TYPE];

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

  // Shows/hides markers by type.
  void toggleMarkerByTypeId(
    String markerTypeId,
    bool isVisible,
  ) {
    final markerType = _getMarkerTypeById(markerTypeId);
    final markerTypeIndex = markersTypes.indexOf(markerType);

    markersTypes[markerTypeIndex] = markerType.copyWith(
      isVisible: isVisible,
    );

    // Used to trigger rendering. Marker types values are read sync.
    _toggleMarkersByTypes$.sink.add(null);
  }

  bool isMarkerTypeVisible(String markerTypeId) {
    final markerType = _getMarkerTypeById(markerTypeId);

    return markerType.isVisible;
  }

  // === PRIVATE ===

  MarkerTypeM _getMarkerTypeById(String markerTypeId) {
    return markersTypes.firstWhere((type) => type.id == markerTypeId);
  }
}
