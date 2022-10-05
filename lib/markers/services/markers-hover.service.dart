import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';

import '../../blocks/services/text-lines.utils.dart';
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
// Then we cache the new hovered markers in the state store and trigger a new editor refresh (build cycle).
// When the editor is running the build cycle each line will check again for markers that it has to draw and
// will apply the hovering color according to the hovered markers from the state stare.
class MarkersHoverService {
  final _textLinesUtils = TextLinesUtils();

  final List<String> _hoveredMarkersIds = [];
  final List<String> _prevHoveredMarkersIds = [];

  factory MarkersHoverService() => _instance;

  static final _instance = MarkersHoverService._privateConstructor();

  MarkersHoverService._privateConstructor();

  // Multiple overlapping highlights can be intersected at the same time.
  // Intersecting all highlights avoids "masking" highlights and making them inaccessible.
  // If you need only the highlight hovering highest on top, you'll need to implement
  // custom logic on the client side to select the preferred highlight.
  void onHover(PointerHoverEvent event, EditorState state) {
    _hoveredMarkersIds.clear();

    // Detect Hovering
    // Multiple markers can overlap, we can't end the search eagerly
    state.markers.markers.forEach((marker) {
      final isHovered = _isMarkerHovered(event.position, marker, state);

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
      _enterMarker(addedMarker, state);
    });

    // On Hover
    _hoveredMarkersIds.forEach((id) {
      final marker = state.markers.markers.firstWhere(
        (_marker) => _marker.id == id,
      );
      final type = _getMarkerTypeById(marker.type, state);

      if (type?.onHover != null) {
        type?.onHover!(marker);
      }
    });

    // On Exit
    removedIds.forEach((id) {
      final removedMarker = state.markers.markers.firstWhere(
        (_marker) => _marker.id == id,
      );
      _exitMarker(removedMarker, state);
    });

    // Prev Hovered Markers
    _prevHoveredMarkersIds
      ..clear()
      ..addAll(_hoveredMarkersIds);
  }

  void onSingleTapUp(TapUpDetails details, EditorState state) {
    _detectTapOnMarker(details, state);
  }

  // === PRIVATE ===

  void _enterMarker(MarkerM marker, EditorState state) {
    final type = _getMarkerTypeById(marker.type, state);

    if (type?.onEnter != null) {
      type?.onEnter!(marker);
    }

    state.markers.enterMarkerById(marker.id);
    state.refreshEditor.refreshEditorWithoutCaretPlacement();
  }

  void _exitMarker(MarkerM marker, EditorState state) {
    final type = _getMarkerTypeById(marker.type, state);

    if (type?.onExit != null) {
      type?.onExit!(marker);
    }

    state.markers.exitMarkerById(marker.id);
    state.refreshEditor.refreshEditorWithoutCaretPlacement();
  }

  bool _isMarkerHovered(
    Offset eventPos,
    MarkerM marker,
    EditorState state,
  ) {
    assert(
      marker.rectangles != null,
      'Attempting to hover over a marker that was not yet rendered.'
      "This means we don't know the screen coordinates for this marker",
    );

    var isHovered = false;
    var scrollOffset = 0.0;

    // Scroll Offset
    if (state.editorConfig.config.scrollable == true) {
      scrollOffset = state.refs.scrollController.offset;
    }

    // Sync Pointer To Lines
    final pointer = Offset(
      eventPos.dx - (marker.docRelPosition?.dx ?? 0),
      eventPos.dy - (marker.docRelPosition?.dy ?? 0) + scrollOffset,
    );

    // Search For Hits
    for (final rectangle in marker.rectangles ?? []) {
      isHovered = _textLinesUtils.isRectangleHovered(rectangle, pointer);

      // Exit search loop early as soon as the first hit is found (perf)
      if (isHovered) {
        break;
      }
    }

    return isHovered;
  }

  MarkerTypeM? _getMarkerTypeById(String markerType, EditorState state) {
    return state.markersTypes.types.firstWhereOrNull(
      (type) => type.id == markerType,
    );
  }

  void _detectTapOnMarker(TapUpDetails details, EditorState state) {
    // Search For Hits
    // Multiple markers can overlap, we can't end the search eagerly
    for (final marker in state.markers.markers) {
      final isHovered = _isMarkerHovered(details.globalPosition, marker, state);

      if (isHovered) {
        final type = _getMarkerTypeById(marker.type, state);

        if (type?.onSingleTapUp != null) {
          type?.onSingleTapUp!(marker);
        }
      }
    }
  }
}
