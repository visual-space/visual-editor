import 'package:collection/collection.dart';

import '../models/highlight.model.dart';

class HighlightsState {
  // === HIGHLIGHTS ===

  List<HighlightM> _highlights = [];

  List<HighlightM> get highlights => _highlights;

  void setHighlights(List<HighlightM> highlights) {
    _highlights = highlights;
  }

  void addHighlight(HighlightM highlight) {
    _highlights.add(highlight);
  }

  void removeHighlight(HighlightM highlight) {
    _highlights.remove(highlight);
  }

  void removeAllHighlights() {
    _highlights = [];
  }

  // === HOVERED HIGHLIGHTS ===

  final List<HighlightM> _hoveredHighlights = [];

  List<HighlightM> get hoveredHighlights => _hoveredHighlights;

  // Pointer has entered one of the rectangles of a highlight
  void enterHighlightById(String id) {
    final highlight = _highlights.firstWhereOrNull(
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
