import '../../shared/models/selection-rectangles.model.dart';

class SelectedLinkState {
  // === SELECTED LINK RECTANGLES ===

  // After selecting a link, we need to cache its rectangles in order to display the link menu
  late List<SelectionRectanglesM> _selectedLinkRectangles;

  List<SelectionRectanglesM>? get selectedLinkRectangles => _selectedLinkRectangles;

  void setSelectedLinkRectangles(List<SelectionRectanglesM> rectangles) =>
      _selectedLinkRectangles = rectangles;
}