import 'package:collection/collection.dart';

import '../models/highlight.model.dart';

class HighlightsState {
  // === HIGHLIGHTS ===

  List<HighlightM> highlights = [];

  void addHighlight(HighlightM highlight) {
    highlights.add(highlight);
  }

  void removeHighlight(HighlightM highlight) {
    highlights.remove(highlight);
  }

  void removeHighlightsById(String id) {
    highlights.removeWhere(
      (highlight) => highlight.id == id,
    );
  }

  void removeAllHighlights() {
    highlights = [];
  }

  // === HOVERED HIGHLIGHTS ===

  final List<HighlightM> _hoveredHighlights = [];

  List<HighlightM> get hoveredHighlights => _hoveredHighlights;

  // Pointer has entered one of the rectangles of a highlight
  void enterHighlightById(String id) {
    final highlight = highlights.firstWhereOrNull(
      (highlight) => highlight.id == id,
    );

    if (highlight != null) {
      _hoveredHighlights.add(highlight);
    }
  }

  // Pointer has exited the rectangles of a highlight
  void exitHighlightById(String id) {
    final highlight = _hoveredHighlights.firstWhereOrNull(
      (highlight) => highlight.id == id,
    );

    if (highlight != null) {
      _hoveredHighlights.remove(highlight);
    }
  }
}
