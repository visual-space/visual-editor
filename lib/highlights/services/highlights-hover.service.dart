import 'package:flutter/gestures.dart';

import '../../blocks/services/text-lines.utils.dart';
import '../../highlights/models/highlight.model.dart';
import '../../shared/state/editor.state.dart';

// In Flutter we don't have any built in mechanic for easily detecting hover over random stretches of text.
// Therefore we have to write our own code for detecting hovering over highlights.
// When the editor is initialised we store all the highlights in the state store.
// Once the build() method is executed we have references to all the rendering classes for every single class.
// Using a callback after build we query every single line to check if it has highlights,
// and if so we request the rectangles needed to draw the highlights.
// Since one highlights can contain multiple lines we group the markers in batches.
// For each line we cache also the local to global offset.
// This offset will be essential to align the pointer coordinates with the highlights rectangles coordinates.
// Once we have the rectangles we cache them by deep cloning the highlights to include this information.
// When the user pointer enters the editor screen space then the TextGestures widget matches the correct action (onHover).
// In the on hover method we check every single highlight to see if any of the rectangles are intersected by the pointer.
// Once one or many highlights are matched we then cache the ids.
// On every single hover event we compare if new ids have been added or removed.
// For each added or removed highlight we run the corresponding callbacks.
// Then we cache the new hovered highlights in the state store and trigger a new editor refresh (build cycle).
// When the editor is running the build cycle each line will check again for highlights that it has to draw and
// will apply the hovering color according to the hovered highlights from the state stare.
class HighlightsHoverService {
  final _textLinesUtils = TextLinesUtils();

  final List<String> _hoveredHighlightsIds = [];
  final List<String> _prevHoveredHighlightsIds = [];

  factory HighlightsHoverService() => _instance;

  static final _instance = HighlightsHoverService._privateConstructor();

  HighlightsHoverService._privateConstructor();

  // Multiple overlapping highlights can be intersected at the same time.
  // Intersecting all highlights avoids "masking" highlights and making them inaccessible.
  // If you need only the highlight hovering highest on top, you'll need to implement
  // custom logic on the client side to select the preferred highlight.
  void onHover(PointerHoverEvent event, EditorState state) {
    _hoveredHighlightsIds.clear();

    // Detect Hovering
    // Multiple highlights can overlap, we can't end the search eagerly
    state.highlights.highlights.forEach((highlight) {
      final isHovered = _isHighlightHovered(event.position, highlight, state);

      if (isHovered) {
        _hoveredHighlightsIds.add(highlight.id);
      }
    });

    // Added, Removed
    final addedIds = _hoveredHighlightsIds
        .where((id) => !_prevHoveredHighlightsIds.contains(id))
        .toList();
    final removedIds = _prevHoveredHighlightsIds
        .where((id) => !_hoveredHighlightsIds.contains(id))
        .toList();

    // (!) Beware that the callback need to be invoked in a particular order.
    // If changing this service don't mix-up the order of the events.

    // On Enter
    addedIds.forEach((id) {
      final addedHighlight = state.highlights.highlights
          .firstWhere((highlight) => highlight.id == id);
      _enterHighlight(addedHighlight, state);
    });

    // On Hover
    _hoveredHighlightsIds.forEach((id) {
      final highlight = state.highlights.highlights.firstWhere(
        (highlight) => highlight.id == id,
      );

      if (highlight.onHover != null) {
        highlight.onHover!(highlight);
      }
    });

    // On Exit
    removedIds.forEach((id) {
      final removeHighlight = state.highlights.highlights.firstWhere(
        (highlight) => highlight.id == id,
      );
      _exitHighlight(removeHighlight, state);
    });

    // Prev Hovered Highlights
    _prevHoveredHighlightsIds
      ..clear()
      ..addAll(_hoveredHighlightsIds);
  }

  void onSingleTapUp(TapUpDetails details, EditorState state) {
    _detectTapOnHighlight(details, state);
  }

  // === PRIVATE ===

  void _enterHighlight(HighlightM highlight, EditorState state) {
    if (highlight.onEnter != null) {
      highlight.onEnter!(highlight);
    }

    state.highlights.enterHighlightById(highlight.id);
    state.refreshEditor.refreshEditorWithoutCaretPlacement();
  }

  void _exitHighlight(HighlightM highlight, EditorState state) {
    if (highlight.onExit != null) {
      highlight.onExit!(highlight);
    }

    state.highlights.exitHighlightById(highlight.id);
    state.refreshEditor.refreshEditorWithoutCaretPlacement();
  }

  bool _isHighlightHovered(
    Offset eventPos,
    HighlightM highlight,
    EditorState state,
  ) {
    assert(
      highlight.rectanglesByLines != null,
      'Attempting to hover over a highlight that was not yet rendered.'
      "This means we don't know the screen coordinates for this highlight",
    );

    var highlightIsHovered = false;
    var scrollOffset = 0.0;

    // Scroll Offset
    if (state.editorConfig.config.scrollable == true) {
      scrollOffset = state.refs.scrollController.offset;
    }

    for (final line in highlight.rectanglesByLines!) {
      final pointer = Offset(
        eventPos.dx - (line.docRelPosition.dx),
        eventPos.dy - (line.docRelPosition.dy) + scrollOffset,
      );

      for (final rectangle in line.rectangles) {
        final isHovered = _textLinesUtils.isRectangleHovered(
          rectangle,
          pointer,
        );

        if (isHovered) {
          highlightIsHovered = true;
          break;
        }
      }

      // Exit search loop early as soon as the first hit is found (perf)
      if (highlightIsHovered) {
        break;
      }
    }

    return highlightIsHovered;
  }

  void _detectTapOnHighlight(TapUpDetails details, EditorState state) {
    // Search For Hits
    // Multiple markers can overlap, we can't end the search eagerly
    for (final highlight in state.highlights.highlights) {
      final isHovered = _isHighlightHovered(
        details.globalPosition,
        highlight,
        state,
      );

      if (isHovered && highlight.onSingleTapUp != null) {
        highlight.onSingleTapUp!(highlight);
      }
    }
  }
}
