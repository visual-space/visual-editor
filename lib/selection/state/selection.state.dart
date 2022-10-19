import 'package:flutter/material.dart';

import '../../shared/models/selection-rectangles.model.dart';

// TODO Move the selection from controller to state
class SelectionState {
  // === SELECTION RECTANGLES ===

  // Once the document is rendered in lines and blocks we extract from each line the selection rectangles.
  // Selection can span multiple lines, therefore we need for each line the document relative offset.
  List<SelectionRectanglesM> _selectionRectangles = [];

  List<SelectionRectanglesM> get selectionRectangles => _selectionRectangles;

  void setSelectionRectangles(List<SelectionRectanglesM> rectangles) =>
      _selectionRectangles = rectangles;

  // === ORIGIN ===

  // Used on Desktop (mouse and keyboard enabled platforms) as base offset
  // for extending selection, either with combination of `Shift` + Click or by dragging.
  // TODO A plain getter setter pair does not help. Remove them.
  TextSelection? _origin;

  TextSelection? get origin => _origin;

  void setOrigin(TextSelection? origin) => _origin = origin;

  // === LAST TAP DOWN ===
}
