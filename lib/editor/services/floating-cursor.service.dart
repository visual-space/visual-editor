import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../const/k-floating.dart';
import '../state/editor-config.state.dart';
import '../widgets/editor-renderer.dart';
import 'editor-renderer.utils.dart';

// The floating cursor helps users see where the cursor is going to be placed
// while their finger is obscuring the view.
class FloatingCursorService {
  final _editorConfigState = EditorConfigState();
  final _editorRendererUtils = EditorRendererUtils();

  // The relative origin in relation to the distance the user has theoretically dragged the floating cursor offscreen.
  // This value is used to account for the difference in the rendering position and the raw offset value.
  Offset _relativeOrigin = Offset.zero;
  Offset? _previousOffset;
  bool _resetOriginOnLeft = false;
  bool _resetOriginOnRight = false;
  bool _resetOriginOnTop = false;
  bool _resetOriginOnBottom = false;
  bool _floatingCursorOn = false;

  static final _instance = FloatingCursorService._privateConstructor();

  factory FloatingCursorService() => _instance;

  FloatingCursorService._privateConstructor();

  // Returns the position within the editor closest to the raw cursor offset.
  Offset calculateBoundedFloatingCursorOffset(
    Offset rawCursorOffset,
    double preferredLineHeight,
    EditorRenderer editorRenderer,
  ) {
    var deltaPosition = Offset.zero;
    final topBound = kFloatingCursorAddedMargin.top;
    final bottomBound = editorRenderer.size.height -
        preferredLineHeight +
        kFloatingCursorAddedMargin.bottom;
    final leftBound = kFloatingCursorAddedMargin.left;
    final rightBound =
        editorRenderer.size.width - kFloatingCursorAddedMargin.right;

    if (_previousOffset != null) {
      deltaPosition = rawCursorOffset - _previousOffset!;
    }

    // If the raw cursor offset has gone off an edge,
    // we want to reset the relative origin of
    // the dragging when the user drags back into the field.
    if (_resetOriginOnLeft && deltaPosition.dx > 0) {
      _relativeOrigin = Offset(
        rawCursorOffset.dx - leftBound,
        _relativeOrigin.dy,
      );
      _resetOriginOnLeft = false;
    } else if (_resetOriginOnRight && deltaPosition.dx < 0) {
      _relativeOrigin = Offset(
        rawCursorOffset.dx - rightBound,
        _relativeOrigin.dy,
      );
      _resetOriginOnRight = false;
    }
    if (_resetOriginOnTop && deltaPosition.dy > 0) {
      _relativeOrigin = Offset(
        _relativeOrigin.dx,
        rawCursorOffset.dy - topBound,
      );
      _resetOriginOnTop = false;
    } else if (_resetOriginOnBottom && deltaPosition.dy < 0) {
      _relativeOrigin = Offset(
        _relativeOrigin.dx,
        rawCursorOffset.dy - bottomBound,
      );
      _resetOriginOnBottom = false;
    }

    final currentX = rawCursorOffset.dx - _relativeOrigin.dx;
    final currentY = rawCursorOffset.dy - _relativeOrigin.dy;
    final double adjustedX = math.min(
      math.max(currentX, leftBound),
      rightBound,
    );
    final double adjustedY = math.min(
      math.max(currentY, topBound),
      bottomBound,
    );
    final adjustedOffset = Offset(adjustedX, adjustedY);

    if (currentX < leftBound && deltaPosition.dx < 0) {
      _resetOriginOnLeft = true;
    } else if (currentX > rightBound && deltaPosition.dx > 0) {
      _resetOriginOnRight = true;
    }

    if (currentY < topBound && deltaPosition.dy < 0) {
      _resetOriginOnTop = true;
    } else if (currentY > bottomBound && deltaPosition.dy > 0) {
      _resetOriginOnBottom = true;
    }

    _previousOffset = rawCursorOffset;

    return adjustedOffset;
  }

  // Sets the screen position of the floating cursor and the text position closest to the cursor.
  // `resetLerpValue` drives the size of the floating cursor.
  void setFloatingCursor(
    FloatingCursorDragState dragState,
    Offset boundedOffset,
    TextPosition textPosition,
    EditorRenderer editorRenderer, {
    double? resetLerpValue,
  }) {
    if (_editorConfigState.config.floatingCursorDisabled) return;

    if (dragState == FloatingCursorDragState.Start) {
      _relativeOrigin = Offset.zero;
      _previousOffset = null;
      _resetOriginOnBottom = false;
      _resetOriginOnTop = false;
      _resetOriginOnRight = false;
      _resetOriginOnBottom = false;
    }

    _floatingCursorOn = dragState != FloatingCursorDragState.End;

    if (_floatingCursorOn) {
      editorRenderer.floatingCursorTextPosition = textPosition;
      final sizeAdjustment = resetLerpValue != null
          ? EdgeInsets.lerp(
              kFloatingCaretSizeIncrease,
              EdgeInsets.zero,
              resetLerpValue,
            )!
          : kFloatingCaretSizeIncrease;
      final child =
          _editorRendererUtils.childAtPosition(textPosition, editorRenderer);
      final caretPrototype = child.getCaretPrototype(
        child.globalToLocalPosition(textPosition),
      );
      editorRenderer.floatingCursorRect = sizeAdjustment
          .inflateRect(
            caretPrototype,
          )
          .shift(boundedOffset);
      editorRenderer.cursorController.setFloatingCursorTextPosition(
        editorRenderer.floatingCursorTextPosition,
      );
    } else {
      editorRenderer.floatingCursorRect = null;
      editorRenderer.cursorController.setFloatingCursorTextPosition(null);
    }
  }
}
