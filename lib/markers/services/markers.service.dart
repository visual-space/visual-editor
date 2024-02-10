import '../../document/models/attributes/attribute-scope.enum.dart';
import '../../document/models/attributes/attribute.model.dart';
import '../../document/models/attributes/attributes.model.dart';
import '../../document/models/material/test-selection.model.dart';
import '../../document/services/nodes/attribute.utils.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/utils/string.utils.dart';
import '../../styles/services/styles.service.dart';
import '../const/default-marker-type.const.dart';
import '../models/marker-type.model.dart';
import '../models/marker.model.dart';

// Adds and removes markers from the document
class MarkersService {
  late final StylesService _stylesService;

  final EditorState state;

  MarkersService(this.state) {
    _stylesService = StylesService(state);
  }

  void addMarker(String markerTypeId) {
    // Existing markers
    final style = _stylesService.getSelectionStyle();
    final styleAttributes = style.values.toList();

    List<MarkerM>? markers = [];

    // Get Existing Markers
    if (styleAttributes.isNotEmpty) {
      final markersMap = styleAttributes.firstWhere(
        (attribute) => attribute.key == AttributesM.markers.key,
        orElse: () => AttributeM('', AttributeScope.INLINE, null),
      );

      if (markersMap.key != '') {
        markers = markersMap.value;
      }
    }

    // On Add Callback
    // Returns the UUIDs or whatever custom data the client app desires
    // to store inline as a value of hte marker attribute.
    final markersTypes = state.markersTypes.markersTypes;

    final MarkerTypeM? markerType = markersTypes.firstWhere(
      (type) => type.id == markerTypeId,
      orElse: () => DEFAULT_MARKER_TYPE,
    );

    var data;

    // The client app is given the option to generate a random UUID and save it in the marker on marker creation.
    // This UUID can be used to link the marker to entries from another table where you can keep additional metadata about this marker.
    // For ex: You can have a marker linked to a user profile by the user profile UUID.
    // By using UUIDs we can avoid duplicating metadata in the delta json when we copy paste markers.
    // It also keeps the delta document lightweight.
    if (markerType != null && markerType.onAddMarkerViaToolbar != null) {
      data = markerType.onAddMarkerViaToolbar!(markerType);
    }

    final marker = MarkerM(
      textSelection: TextSelectionM(
        extentOffset: state.selection.selection.extentOffset,
        baseOffset: state.selection.selection.baseOffset,
      ),
      id: getTimeBasedId(),
      type: markerTypeId,
      data: data,
    );

    // Add the new marker
    markers?.add(marker);

    // Markers are stored as json data in the styles
    final jsonMarkers = markers?.map((marker) => marker.toJson()).toList();
    final attribute = AttributeUtils.fromKeyValue(AttributesM.markers.key, jsonMarkers);

    // Add to document
    _stylesService.formatSelection(attribute);
  }

  // Because we can have the same marker copied in different parts of the
  // document we have to delete all markers with the same id
  void deleteMarkerById(String markerId) {
    state.markers.markers.forEach((marker) {
      if (marker.id == markerId) {
        assert(
          marker.textSelection != null,
          "Can't find text selection data on the marker. Therefore we can't remove the marker",
        );

        final index = marker.textSelection?.baseOffset ?? 0;
        final length = (marker.textSelection?.extentOffset ?? 0) - (marker.textSelection?.baseOffset ?? 0);
        final markerAttribute = AttributeUtils.fromKeyValue(AttributesM.markers.key, null);

        _stylesService.formatTextRange(index, length, markerAttribute);
      }
    });
  }

  void toggleMarkers(bool areVisible) {
    state.markersVisibility.toggleMarkers(areVisible);
  }

  void toggleMarkerHighlightVisibilityByTypeId(String markerType, bool isVisible) {
    state.markersTypes.toggleMarkerHighlightVisibilityByTypeId(markerType, isVisible);
  }

  void toggleMarkerTextVisibilityByTypeId(String markerType, bool isVisible) {
    state.markersTypes.toggleMarkerTextVisibilityByTypeId(markerType, isVisible);
  }

  void toggleMarkerTextVisibilityByMarkerId(String markerId, bool isVisible) {
    state.markersTypes.toggleMarkerTextVisibilityByMarkerId(markerId, isVisible);
  }

  bool getMarkersVisibility() {
    return state.markersVisibility.visibility;
  }

  bool isMarkerTypeHighlightVisible(String markerType) {
    return state.markersTypes.isMarkerTypeHighlightVisible(markerType);
  }

  bool isMarkerTypeTextVisible(String markerType) {
    return state.markersTypes.isMarkerTypeTextVisible(markerType);
  }

  List<MarkerM> getAllMarkers() {
    return state.markers.markers;
  }
}
