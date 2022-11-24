import 'dart:async';

import '../const/default-marker-type.const.dart';
import '../models/marker-type.model.dart';

// Before initialising the editor we need to provide a list of markers types
// that are available for insertion in the delta document.
// Controls also the visibility of every marker type.
class MarkersTypesState {
  final _toggleMarkersByTypes$ = StreamController<void>.broadcast();
  List<MarkerTypeM> _types = [DEFAULT_MARKER_TYPE];

  List<MarkerTypeM> get types => _types;

  Stream<void> get toggleMarkersByTypes$ => _toggleMarkersByTypes$.stream;

  void setMarkersTypes(List<MarkerTypeM> types) {
    _types = types;
  }

  void addMarkerType(MarkerTypeM type) {
    _types.add(type);
  }

  void removeMarkerType(MarkerTypeM type) {
    _types.remove(type);
  }

  void removeAllMarkersTypes() {
    _types = [];
  }

  // Shows/hides markers by type.
  void toggleMarkerByTypeId(
    String markerTypeId,
    bool isVisible,
  ) {
    final markerType = _getMarkerTypeById(markerTypeId);
    final markerTypeIndex = _types.indexOf(markerType);

    _types[markerTypeIndex] = markerType.copyWith(
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
    return _types.firstWhere((type) => type.id == markerTypeId);
  }
}
