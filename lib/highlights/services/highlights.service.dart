import 'package:flutter/gestures.dart';

import '../../blocks/services/lines-blocks.service.dart';
import '../../highlights/models/highlight.model.dart';
import '../../shared/state/editor.state.dart';

class HighlightsService {
  final _linesBlocksService = LinesBlocksService();

  final List<HighlightM> _prevHoveredHighlights = [];

  factory HighlightsService() => _instance;

  static final _instance = HighlightsService._privateConstructor();

  HighlightsService._privateConstructor();

  void onHover(PointerHoverEvent event, EditorState state) {
    final position = _linesBlocksService.getPositionForOffset(
      event.position,
      state,
    );

    // Multiple overlapping highlights can be intersected at the same time.
    // Intersecting all highlights avoid "burying" highlights and making them inaccessible.
    // If you need only the highlight hovering highest on top, you'll need to implement
    // custom logic on the client side to select the preferred highlight.
    state.highlights.clearHoveredHighlights();

    state.highlights.highlights.forEach((highlight) {
      final start = highlight.textSelection.start;
      final end = highlight.textSelection.end;
      final isHovered = start <= position.offset && position.offset <= end;
      final wasHovered = _prevHoveredHighlights.contains(highlight);

      if (isHovered) {
        state.highlights.hoverHighlight(highlight);

        if (!wasHovered && highlight.onEnter != null) {
          highlight.onEnter!(highlight);

          // Only once at enter to avoid performance issues
          // Could be further improved if multiple highlights overlap
          state.highlights.hoverHighlight(highlight);
        }

        if (highlight.onHover != null) {
          highlight.onHover!(highlight);
        }
      } else {
        if (wasHovered && highlight.onLeave != null) {
          highlight.onLeave!(highlight);

          // Only once at exit to avoid performance issues
          state.highlights.exitHighlight(highlight);
        }
      }
    });

    _prevHoveredHighlights.clear();
    _prevHoveredHighlights.addAll(state.highlights.hoveredHighlights);
  }

  void onSingleTapUp(TapUpDetails details, EditorState state) {
    if (state.editorConfig.config.onTapUp != null &&
        state.editorConfig.config.onTapUp!(
          details,
          _linesBlocksService.getPositionForOffset,
        )) {
      return;
    }

    _detectTapOnHighlight(details, state);
  }

  void _detectTapOnHighlight(TapUpDetails details, EditorState state) {
    final position = _linesBlocksService.getPositionForOffset(
      details.globalPosition,
      state,
    );

    state.highlights.highlights.forEach((highlight) {
      final start = highlight.textSelection.start;
      final end = highlight.textSelection.end;
      final isTapped = start <= position.offset && position.offset <= end;

      if (isTapped && highlight.onSingleTapUp != null) {
        highlight.onSingleTapUp!(highlight);
      }
    });
  }
}
