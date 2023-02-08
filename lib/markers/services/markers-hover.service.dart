import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';

import '../../doc-tree/services/rectangles.service.dart';
import '../../shared/state/editor.state.dart';
import '../models/marker-type.model.dart';
import '../models/marker.model.dart';

// In Flutter we don't have any built in mechanic for easily detecting hover over random stretches of text.
// Therefore we have to write our own code for detecting hovering over markers.
// When the editor is initialised we store all the markers in the state store.
// Once the build() method is executed we have references to all the rendering classes for every single class.
// Using a callback after build we query every single line to check if it has markers,
// and if so we request the rectangles needed to draw the markers.
// Unlike highlights, markers are sliced per line by default (when DeltaM is converted to DocumentM).
// For each marker we cache also the local to global offset of the line where it is hosted.
// This offset will be essential to align the pointer coordinates with the markers rectangles coordinates.
// Once we have the rectangles we cache them by deep cloning the markers to include this information.
// When the user pointer enters the editor screen space then the TextGestures widget matches the correct action (onHover).
// In the on hover method we check every single marker to see if any of the rectangles are intersected by the pointer.
// Once one or many markers are matched we then cache the ids.
// On every single hover event we compare if new ids have been added or removed.
// For each added or removed marker we run the corresponding callbacks defined by the marker type.
// Then we cache the new hovered markers in the state store and trigger a new editor build (layout update).
// When the editor is running the build cycle each line will check again for markers that it has to draw and
// will apply the hovering color according to the hovered markers from the state stare.
class MarkersHoverService {
  late final RectanglesService _rectanglesService;

  // No need to move to state since this service is initialised only once in TextGestures widget (no duplicated state).
  final List<String> _hoveredMarkersIds = [];
  final List<String> _prevHoveredMarkersIds = [];
  final EditorState state;

  MarkersHoverService(this.state) {
    _rectanglesService = RectanglesService(state);
  }

  // Multiple overlapping highlights can be intersected at the same time.
  // Intersecting all highlights avoids "masking" highlights and making them inaccessible.
  // If you need only the highlight hovering highest on top, you'll need to implement
  // custom logic on the client side to select the preferred highlight.
  void onHover(PointerHoverEvent event) {
    _hoveredMarkersIds.clear();

    // Detect Hovering
    // Multiple markers can overlap, we can't end the search eagerly
    state.markers.markers.forEach((marker) {
      final isHovered = _isMarkerHovered(event.position, marker);

      if (isHovered) {
        _hoveredMarkersIds.add(marker.id);
      }
    });

    // Added, Removed
    final addedIds = _hoveredMarkersIds
        .where((id) => !_prevHoveredMarkersIds.contains(id))
        .toList();
    final removedIds = _prevHoveredMarkersIds
        .where((id) => !_hoveredMarkersIds.contains(id))
        .toList();

    // (!) Beware that the callback need to be invoked in a particular order.
    // If changing this service don't mix-up the order of the events.

    // On Enter
    addedIds.forEach((id) {
      final addedMarker = state.markers.markers.firstWhere(
        (marker) => marker.id == id,
      );
      _enterMarker(addedMarker);
    });

    // On Hover
    _hoveredMarkersIds.forEach((id) {
      final marker = state.markers.markers.firstWhere(
        (_marker) => _marker.id == id,
      );
      final type = _getMarkerTypeById(marker.type);

      if (type?.onHover != null) {
        type?.onHover!(marker);
      }
    });

    // On Exit
    removedIds.forEach((id) {
      final removedMarker = state.markers.markers.firstWhere(
        (_marker) => _marker.id == id,
      );
      _exitMarker(removedMarker);
    });

    // Prev Hovered Markers
    _prevHoveredMarkersIds
      ..clear()
      ..addAll(_hoveredMarkersIds);
  }

  void onSingleTapUp(TapUpDetails details) {
    _detectTapOnMarker(details);
  }

  // === PRIVATE ===

  void _enterMarker(MarkerM marker) {
    final type = _getMarkerTypeById(marker.type);

    if (type?.onEnter != null) {
      type?.onEnter!(marker);
    }

    state.markers.enterMarkerById(marker.id);
    state.runBuild.runBuildWithoutCaretPlacement();
  }

  void _exitMarker(MarkerM marker) {
    final type = _getMarkerTypeById(marker.type);

    if (type?.onExit != null) {
      type?.onExit!(marker);
    }

    state.markers.exitMarkerById(marker.id);
    state.runBuild.runBuildWithoutCaretPlacement();
  }

  bool _isMarkerHovered(Offset eventPos, MarkerM marker) {
    assert(
      marker.rectangles != null,
      'Attempting to hover over a marker that was not yet rendered.'
      "This means we don't know the screen coordinates for this marker",
    );

    var isHovered = false;

    // Sync Pointer To Lines
    final pointer = Offset(
      eventPos.dx - (marker.docRelPosition?.dx ?? 0),
      eventPos.dy - (marker.docRelPosition?.dy ?? 0),
    );
    final editorOffset = state.refs.renderer.localToGlobal(Offset.zero);

    // Search For Hits
    for (final rectangle in marker.rectangles ?? []) {
      isHovered = _rectanglesService.isRectangleHovered(
        rectangle,
        pointer,
        editorOffset,
      );

      // Exit search loop early as soon as the first hit is found (perf)
      if (isHovered) {
        break;
      }
    }

    return isHovered;
  }

  MarkerTypeM? _getMarkerTypeById(String markerType) {
    return state.markersTypes.markersTypes.firstWhereOrNull(
      (type) => type.id == markerType,
    );
  }

  void _detectTapOnMarker(TapUpDetails details) {
    // Search For Hits
    // Multiple markers can overlap, we can't end the search eagerly
    for (final marker in state.markers.markers) {
      final isHovered = _isMarkerHovered(details.globalPosition, marker);

      if (isHovered) {
        final type = _getMarkerTypeById(marker.type);

        if (type?.onSingleTapUp != null) {
          type?.onSingleTapUp!(marker);
        }
      }
    }
  }
}
