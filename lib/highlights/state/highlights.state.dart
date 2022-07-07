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

  void hoverHighlight(HighlightM highlight) {
    _hoveredHighlights.add(highlight);
  }

  void exitHighlight(HighlightM highlight) {
    _hoveredHighlights.remove(highlight);
  }

  // TODO REVIEW
  void clearHoveredHighlights() {}
}
