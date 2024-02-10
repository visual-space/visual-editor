import '../../document/models/attributes/attributes.model.dart';
import '../../document/models/delta/operation.model.dart';
import '../../document/models/material/test-selection.model.dart';
import '../../document/models/nodes/style.model.dart';
import '../models/marker.model.dart';

class MarkersUtils {
  void addBaseAndExtentToMarkers(StyleM? style, int offset, OperationM operation) {
    final hasMarkers = style?.attributes.keys.toList().contains(AttributesM.markers.key) ?? false;

    if (hasMarkers) {
      final markers = style!.attributes[AttributesM.markers.key]!.value as List<MarkerM>;

      // Cache text selection for convenience.
      // We will need it later at runtime for deleting markers.
      final _markersWithTextSel = markers.map((marker) {
        return MarkerM(
          id: marker.id,
          type: marker.type,
          data: marker.data,
          textSelection: TextSelectionM(
            baseOffset: offset,
            extentOffset: offset + (operation.length ?? 0),
          ),
        );
      }).toList();

      markers.clear();
      markers.addAll(_markersWithTextSel);
    }
  }
}
