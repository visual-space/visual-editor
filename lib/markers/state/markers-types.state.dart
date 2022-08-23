import '../models/marker-type.model.dart';

class MarkersTypesState {
  List<MarkerTypeM> _types = [];

  List<MarkerTypeM> get types => _types;

  void setMarkersTypes(List<MarkerTypeM> types) {
    _types = types;
  }

  void addMarkerType(MarkerTypeM type) {
    _types.add(type);
  }

  void removeMarkerType(MarkerTypeM type) {
    _types.remove(type);
  }

  void removeAllMarkers() {
    _types = [];
  }
}
