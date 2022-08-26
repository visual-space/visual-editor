import 'dart:math';
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

  bool selectionRangeHasHighlight(int baseOffset, int extentOffset) {
    for (final highlight in _highlights) {
      if (_selectionRangeOverlapsHighlightedRange(
          baseOffset, extentOffset, highlight)) {
        return true;
      }
      ;
    }
    return false;
  }

  bool _selectionRangeOverlapsHighlightedRange(
      int baseOffset, int extentOffset, HighlightM highlight) {
    return max(highlight.textSelection.extentOffset,
                highlight.textSelection.baseOffset) >=
            min(baseOffset, extentOffset) &&
        max(baseOffset, extentOffset) >=
            min(highlight.textSelection.baseOffset,
                highlight.textSelection.extentOffset);
  }

  List<HighlightM> getHighlightsInRange(int baseOffset, int extentOffset) {
    List<HighlightM> highlights = [];

    for (final highlight in _highlights) {
      if (_selectionRangeOverlapsHighlightedRange(
          baseOffset, extentOffset, highlight)) {
        highlights.add(highlight);
      }
    }

    return highlights;
  }

  /// Removes all highlights found in this range.
  void removeHighlightsInRange(int baseOffset, int extentOffset) {
    final allHighlights = getHighlightsInRange(baseOffset, extentOffset);
    for (final highlight in allHighlights) {
      _manageHighlightRemovalInRange(extentOffset, baseOffset, highlight);
    }
  }

  /// Removes only the first highlight found for this range.
  /// Only removes the section of the highlight at the range given.
  void removeFirstHighlightInRange(int baseOffset, int extentOffset) {
    final allHighlights = getHighlightsInRange(baseOffset, extentOffset);
    var highlight = highlights.isNotEmpty ? highlights.first : null;
    if (highlight != null) {
      _manageHighlightRemovalInRange(extentOffset, baseOffset, highlight);
    }
  }

  void _manageHighlightRemovalInRange(
      int extentOffset, int baseOffset, HighlightM highlight) {
    var selectionLength =
        max(extentOffset, baseOffset) - min(baseOffset, extentOffset);
    var highlightLength = max(highlight.textSelection.extentOffset,
            highlight.textSelection.baseOffset) -
        min(highlight.textSelection.baseOffset,
            highlight.textSelection.extentOffset);

    // case: base offset smaller than highlight baseoffset and extent offset smaller than highlight extent offset - 1 replacement highlight
    if (baseOffset <= highlight.textSelection.baseOffset &&
        extentOffset < highlight.textSelection.extentOffset) {
      final newHighlight = highlight.copyWithIntExtents(
          baseOffset: extentOffset,
          extentOffset: highlight.textSelection.extentOffset);
      _highlights.remove(highlight);
      _highlights.add(newHighlight);
    }
    // case: base offset smaller than or equal to highlight baseoffset and extent offset larger than or equal to highlight extent offset - 0 replacement highlight
    if (baseOffset <= highlight.textSelection.baseOffset &&
        extentOffset >= highlight.textSelection.extentOffset) {
      _highlights.remove(highlight);
    }
    // case: base offset larger than highlight baseoffset and extent offset smaller than highlight extent offset - 2 replacement highlight
    if (baseOffset > highlight.textSelection.baseOffset &&
        extentOffset < highlight.textSelection.extentOffset) {
      final lowerExtentHighlight = highlight.copyWithIntExtents(
          baseOffset: highlight.textSelection.baseOffset,
          extentOffset: baseOffset);
      final higherExtentHighlight = highlight.copyWithIntExtents(
          baseOffset: extentOffset,
          extentOffset: highlight.textSelection.extentOffset);

      _highlights.remove(highlight);
      _highlights.addAll([lowerExtentHighlight, higherExtentHighlight]);
    }
    // case: base offset larger than highlight baseoffset and extent offset larger than highlight extent offset - 1 replacement highlight
    if (baseOffset > highlight.textSelection.baseOffset &&
        extentOffset >= highlight.textSelection.extentOffset) {
      final newHighlight = highlight.copyWithIntExtents(
          baseOffset: highlight.textSelection.baseOffset,
          extentOffset: baseOffset);
      _highlights.remove(highlight);
      _highlights.add(newHighlight);
    }
  }

  /// Should only be called if a range and highlight are already known to intersect.
  List<int> _getIntersectedRanges(
      int baseOffset, int extentOffset, HighlightM highlight) {
    return [
      max(baseOffset, highlight.textSelection.baseOffset),
      min(extentOffset, highlight.textSelection.extentOffset)
    ];
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
