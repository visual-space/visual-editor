import 'dart:async';

import 'package:flutter/material.dart';
import 'package:visual_editor/highlights/models/highlight.model.dart';
import 'package:visual_editor/markers/models/marker.model.dart';
import 'package:visual_editor/shared/models/selection-rectangles.model.dart';

// Handles all the logic needed to synchronize selection in a page that uses more than an editor
// Every time we need to display the selection menu the editor relative position is required in order to position him in the right place.
// The relative position is calculated using keys that are assigned to editors or other widgets (if they are).
// If the first editor has nothing above them (is the first child of the page) its relative position will be 0.
// This is different from the basic selection menu (see example in the selection menu page)
// by the fact that depends on the position of the editor that triggers it.
class SelectionMenuController {
  // Cache used to temporary store the rectangle, line offset and relative position
  // as delivered by the editor while the scroll offset is changing.
  var _rectangle = TextBox.fromLTRBD(0, 0, 0, 0, TextDirection.ltr);
  Offset? _lineOffset = Offset.zero;
  double _relPos = 0;

  // (!) This stream is extremely important for maintaining the page performance when updating the quick menu position.
  // The _positionQuickMenuAtRectangle() method will be called many times per second when scrolling.
  // Therefore we want to avoid at all costs to setState() in the parent.
  // We will update only the SelectionQuickMenu via the stream.
  // By using this trick we can prevent Flutter from running expensive page updates.
  // We will target our updates only on the area that renders the quick menu (far better performance).
  final quickMenuOffset$ = StreamController<Offset>.broadcast();
  var quickMenuOffset = Offset.zero;

  void displayQuickMenuOnMarker(
    MarkerM marker,
    double scrollOffset,
    double relPos,
  ) {
    final rectangle = marker.rectangles![0];
    final lineOffset = marker.docRelPosition;
    _relPos = relPos;
    _rectangle = rectangle;
    _lineOffset = lineOffset;

    _positionQuickMenuAtRectangle(
      _rectangle,
      _lineOffset,
      scrollOffset,
      relPos,
    );
  }

  void displayQuickMenuOnHighlight(
    HighlightM highlight,
    double scrollOffset,
    double relPos,
  ) {
    final rectangle = highlight.rectanglesByLines![0].rectangles[0];
    final lineOffset = highlight.rectanglesByLines![0].docRelPosition;
    _relPos = relPos;
    _rectangle = rectangle;
    _lineOffset = lineOffset;

    _positionQuickMenuAtRectangle(
      _rectangle,
      _lineOffset,
      scrollOffset,
      relPos,
    );
  }

  void displayQuickMenuOnTextSelection(
    List<SelectionRectanglesM?> rectanglesByLines,
    double scrollOffset,
    double relPos,
  ) {
    final noLinesSelected = rectanglesByLines[0] == null;
    final rectanglesAreMissing = rectanglesByLines[0]!.rectangles.isEmpty;

    // Failsafe
    if (noLinesSelected || rectanglesAreMissing) {
      return;
    }

    final rectangle = rectanglesByLines[0]!.rectangles[0];
    final lineOffset = rectanglesByLines[0]!.docRelPosition;

    _rectangle = rectangle;
    _lineOffset = lineOffset;
    _relPos = relPos;
    _positionQuickMenuAtRectangle(
      _rectangle,
      _lineOffset,
      scrollOffset,
      relPos,
    );
  }

  // Use the updated scroll offset and the existing cached rectangles, line offset and relative position
  void updateQuickMenuPositionAfterScroll(double scrollOffset) {
    _positionQuickMenuAtRectangle(
      _rectangle,
      _lineOffset,
      scrollOffset,
      _relPos,
    );
  }

  // === PRIVATE ===

  void _positionQuickMenuAtRectangle(
    TextBox rectangle,
    Offset? lineOffset,
    double scrollOffset,
    double relPos,
  ) {
    final hMidPoint = rectangle.left + (rectangle.right - rectangle.left) / 2;
    const menuHeight = 31;

    // Menu Position
    final offset = Offset(
      hMidPoint,
      (lineOffset?.dy ?? 0) +
          relPos +
          rectangle.top -
          scrollOffset -
          menuHeight,
    );

    quickMenuOffset = offset;
    quickMenuOffset$.sink.add(offset);
  }
}
