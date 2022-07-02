import 'dart:async';

import '../models/highlight.model.dart';

class HighlightsState {

  // === HIGHLIGHTS ===

  List<HighlightM> _highlights = [];
  final _highlights$ = StreamController<List<HighlightM>>.broadcast();

  List<HighlightM> get highlights => _highlights;

  Stream<List<HighlightM>> get highlights$ => _highlights$.stream;

  void setHighlights(List<HighlightM> highlights) {
    _highlights = highlights;
    _highlights$.sink.add(highlights);
  }

  // === HOVERED HIGHLIGHTS ===

  final List<HighlightM> _hoveredHighlights = [];
  final _hoveredHighlights$ = StreamController<List<HighlightM>>.broadcast();

  List<HighlightM> get hoveredHighlights => _hoveredHighlights;

  Stream<List<HighlightM>> get hoveredHighlights$ => _hoveredHighlights$.stream;

  void setHoveredHighlights(List<HighlightM> highlights) {
    _hoveredHighlights.clear();
    _hoveredHighlights.addAll(highlights);
    _hoveredHighlights$.sink.add(_hoveredHighlights);
  }

  void addHoveredHighlight(HighlightM highlight) {
    _hoveredHighlights.add(highlight);
    _hoveredHighlights$.sink.add(_hoveredHighlights);
  }

  void removeHoveredHighlights(List<HighlightM> highlights) {
    highlights.forEach(_hoveredHighlights.remove);
    _hoveredHighlights$.sink.add(_hoveredHighlights);
  }

  void clearHoveredHighlights() {
    _hoveredHighlights.clear();
    _hoveredHighlights$.sink.add(_hoveredHighlights);
  }
}
