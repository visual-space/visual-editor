import 'package:flutter/gestures.dart';

import '../../editor/services/editor-renderer.utils.dart';
import '../../editor/state/editor-config.state.dart';
import '../../editor/widgets/editor-renderer.dart';
import '../../highlights/models/highlight.model.dart';
import '../../highlights/state/highlights.state.dart';

class HighlightsService {
  static final _editorConfigState = EditorConfigState();
  static final _highlightsState = HighlightsState();
  final _editorRendererUtils = EditorRendererUtils();

  final List<HighlightM> _prevHoveredHighlights = [];

  factory HighlightsService() => _instance;

  static final _instance = HighlightsService._privateConstructor();

  HighlightsService._privateConstructor();

  void onHover(PointerHoverEvent event, EditorRenderer editorRenderer) {
    final position = _editorRendererUtils.getPositionForOffset(
        event.position, editorRenderer);

    // Multiple overlapping highlights can be intersected at the same time.
    // Intersecting all highlights avoid "burying" highlights and making them inaccessible.
    // If you need only the highlight hovering highest on top, you'll need to implement
    // custom logic on the client side to select the preferred highlight.
    _highlightsState.clearHoveredHighlights();

    _highlightsState.highlights.forEach((highlight) {
      final start = highlight.textSelection.start;
      final end = highlight.textSelection.end;
      final isHovered = start <= position.offset && position.offset <= end;
      final wasHovered = _prevHoveredHighlights.contains(highlight);

      if (isHovered) {
        _highlightsState.addHoveredHighlight(highlight);

        if (!wasHovered && highlight.onEnter != null) {
          highlight.onEnter!(highlight);

          // Only once at enter to avoid performance issues
          // Could be further improved if multiple highlights overlap
          // +++ TODO Connect stream to renderer and review if highlights can be add multiple at once.
          _highlightsState.setHoveredHighlights([highlight]);
        }

        if (highlight.onHover != null) {
          highlight.onHover!(highlight);
        }
      } else {
        if (wasHovered && highlight.onLeave != null) {
          highlight.onLeave!(highlight);

          // Only once at exit to avoid performance issues
          _highlightsState.removeHoveredHighlights([highlight]);
        }
      }
    });

    _prevHoveredHighlights.clear();
    _prevHoveredHighlights.addAll(_highlightsState.hoveredHighlights);
  }

  void onSingleTapUp(TapUpDetails details, EditorRenderer editorRenderer,) {
    if (_editorConfigState.config.onTapUp != null &&
        _editorConfigState.config.onTapUp!(
          details,
          (offset) => _editorRendererUtils.getPositionForOffset(
            offset,
            editorRenderer,
          ),
        )) {
      return;
    }

    _detectTapOnHighlight(details, editorRenderer);
  }

  void _detectTapOnHighlight(
    TapUpDetails details,
    EditorRenderer editorRenderer,
  ) {
    final position = _editorRendererUtils.getPositionForOffset(
      details.globalPosition,
      editorRenderer,
    );

    _highlightsState.highlights.forEach((highlight) {
      final start = highlight.textSelection.start;
      final end = highlight.textSelection.end;
      final isTapped = start <= position.offset && position.offset <= end;

      if (isTapped && highlight.onSingleTapUp != null) {
        highlight.onSingleTapUp!(highlight);
      }
    });
  }
}
