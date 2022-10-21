import '../const/default-marker-type.const.dart';
import '../models/marker-type.model.dart';

// Before initialising the editor we need to provide a list of markers types
// that are available for insertion in the delta document.
class MarkersTypesState {
  List<MarkerTypeM> _types = [DEFAULT_MARKER_TYPE];

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

  void removeAllMarkersTypes() {
    _types = [];
  }
}
