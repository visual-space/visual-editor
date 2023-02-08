import 'package:flutter/material.dart';

import '../../shared/models/selection-rectangles.model.dart';

// The selection of text currently highlighted to be edited.
class SelectionState {

  // === SELECTION ===

  TextSelection selection = const TextSelection.collapsed(offset: 0);

  // === SELECTION RECTANGLES ===

  // Once the document is rendered in lines and doc-tree we extract from each line the selection rectangles.
  // Selection can span multiple lines, therefore we need for each line the document relative offset.
  List<SelectionRectanglesM> selectionRectangles = [];

  // === ORIGIN ===

  // Used on Desktop (mouse and keyboard enabled platforms) as base offset
  // for extending selection, either with combination of `Shift` + Click or by dragging.
  TextSelection? origin;

}
