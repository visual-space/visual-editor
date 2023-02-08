import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../doc-tree/services/coordinates.service.dart';
import '../../editor/const/floating.const.dart';
import '../../selection/services/selection.service.dart';
import '../../shared/state/editor.state.dart';
import '../services/caret.service.dart';

// When long pressing the cursor can be moved by dragging your finger on the screen.
// The floating cursor helps users see where the cursor is going to be placed
// while their finger is obscuring the view.
class FloatingCursorController {
  late final CoordinatesService _coordinatesService;
  late final CaretService _caretService;
  late final SelectionService _selectionService;

  // Controls the floating cursor animation when it is released.
  // The floating cursor is animated to merge with the regular cursor.
  late AnimationController _animationController;

  // The relative origin in relation to the distance the user has theoretically dragged the floating cursor offscreen.
  // This value is used to account for the difference in the rendering position and the raw offset value.
  Offset _relativeOrigin = Offset.zero;
  Offset? _previousOffset;
  bool _resetOriginOnLeft = false;
  bool _resetOriginOnRight = false;
  bool _resetOriginOnTop = false;
  bool _resetOriginOnBottom = false;
  bool _floatingCursorOn = false;

  // The original position of the caret on FloatingCursorDragState.start.
  Rect? _startCaretRect;

  // The most recent text position as determined by the location of the floating cursor.
  TextPosition? _lastTextPosition;

  // The offset of the floating cursor as determined from the start call.
  Offset? _pointOffsetOrigin;

  // The most recent position of the floating cursor.
  Offset? _lastBoundedOffset;

  // The time it takes for the floating cursor to snap to the text aligned
  // cursor position after the user has finished placing it.
  final Duration _floatingCursorResetTime = const Duration(milliseconds: 125);
  late EditorState _state;

  FloatingCursorController(EditorState state) {
    _coordinatesService = CoordinatesService(state);
    _caretService = CaretService(state);
    _selectionService = SelectionService(state);

    _cacheStateStore(state);
    _initFloatingCursorAnimationController();
  }

  // Sets the screen position of the floating cursor and the text position closest to the cursor.
  // `resetLerpValue` drives the size of the floating cursor.
  void setFloatingCursor(
    FloatingCursorDragState dragState,
    Offset boundedOffset,
    TextPosition textPosition, {
    double? resetLerpValue,
  }) {
    if (_state.config.floatingCursorDisabled) return;

    if (dragState == FloatingCursorDragState.Start) {
      _relativeOrigin = Offset.zero;
      _previousOffset = null;
      _resetOriginOnBottom = false;
      _resetOriginOnTop = false;
      _resetOriginOnRight = false;
      _resetOriginOnBottom = false;
    }

    _floatingCursorOn = dragState != FloatingCursorDragState.End;
    final renderer = _state.refs.renderer;

    if (_floatingCursorOn) {
      renderer.floatingCursorTextPosition = textPosition;
      final sizeAdjustment = resetLerpValue != null
          ? EdgeInsets.lerp(
              floatingCaretSizeIncrease,
              EdgeInsets.zero,
              resetLerpValue,
            )!
          : floatingCaretSizeIncrease;
      final child = _coordinatesService.childAtPosition(textPosition);
      final caretPrototype = child.getCaretPrototype(
        child.globalToLocalPosition(textPosition),
      );

      renderer.floatingCursorRect =
          sizeAdjustment.inflateRect(caretPrototype).shift(boundedOffset);

      _state.refs.cursorController.setFloatingCursorTextPosition(
        renderer.floatingCursorTextPosition,
      );
    } else {
      renderer.floatingCursorRect = null;
      _state.refs.cursorController.setFloatingCursorTextPosition(null);
    }
  }

  void updateFloatingCursor(RawFloatingCursorPoint point) {
    switch (point.state) {
      case FloatingCursorDragState.Start:
        if (_animationController.isAnimating) {
          _animationController.stop();
          onFloatingCursorResetTick(_animationController);
        }

        // We want to send in points that are centered around a (0,0) origin, so we cache the position.
        _pointOffsetOrigin = point.offset;

        final currentTextPosition = TextPosition(
          offset: _state.selection.selection.baseOffset,
        );
        _startCaretRect = _caretService.getLocalRectForCaret(
          currentTextPosition,
        );

        _lastBoundedOffset = _startCaretRect!.center -
            _floatingCursorOffset(currentTextPosition);
        _lastTextPosition = currentTextPosition;

        setFloatingCursor(
          point.state,
          _lastBoundedOffset!,
          _lastTextPosition!,
        );
        break;

      case FloatingCursorDragState.Update:
        assert(_lastTextPosition != null, 'Last text position was not set');

        final floatingCursorOffset = _floatingCursorOffset(
          _lastTextPosition!,
        );
        final centeredPoint = point.offset! - _pointOffsetOrigin!;
        final rawCursorOffset =
            _startCaretRect!.center + centeredPoint - floatingCursorOffset;

        final preferredLineHeight = _coordinatesService.preferredLineHeight(
          _lastTextPosition!,
        );
        _lastBoundedOffset = _calculateBoundedFloatingCursorOffset(
          rawCursorOffset,
          preferredLineHeight,
        );
        _lastTextPosition = _coordinatesService.getPositionForOffset(
          _state.refs.renderer.localToGlobal(
            _lastBoundedOffset! + floatingCursorOffset,
          ),
        );

        setFloatingCursor(
          point.state,
          _lastBoundedOffset!,
          _lastTextPosition!,
        );

        final newSelection = TextSelection.collapsed(
          offset: _lastTextPosition!.offset,
          affinity: _lastTextPosition!.affinity,
        );

        // Setting selection as floating cursor moves will have scroll view bring background cursor into view
        _selectionService.cacheSelectionAndUpdGuiElems(
          newSelection,
          SelectionChangedCause.forcePress,
        );
        break;

      case FloatingCursorDragState.End:
        // We skip animation if no update has happened.
        if (_lastTextPosition != null && _lastBoundedOffset != null) {
          _animationController
            ..value = 0.0
            ..animateTo(
              1,
              duration: _floatingCursorResetTime,
              curve: Curves.decelerate,
            );
        }
        break;
    }
  }

  // Specifies the floating cursor dimensions and position based the animation controller value.
  // The floating cursor is resized (see [RenderAbstractEditor.setFloatingCursor]) and repositioned
  // (linear interpolation between position of floating cursor and current position of background cursor)
  void onFloatingCursorResetTick(
    AnimationController _floatingCursorAnimationController,
  ) {
    final finalPosition =
        _caretService.getLocalRectForCaret(_lastTextPosition!).centerLeft -
            _floatingCursorOffset(_lastTextPosition!);

    if (_floatingCursorAnimationController.isCompleted) {
      setFloatingCursor(
        FloatingCursorDragState.End,
        finalPosition,
        _lastTextPosition!,
      );
      _startCaretRect = null;
      _lastTextPosition = null;
      _pointOffsetOrigin = null;
      _lastBoundedOffset = null;
    } else {
      final lerpValue = _floatingCursorAnimationController.value;
      final lerpX = lerpDouble(
        _lastBoundedOffset!.dx,
        finalPosition.dx,
        lerpValue,
      )!;
      final lerpY = lerpDouble(
        _lastBoundedOffset!.dy,
        finalPosition.dy,
        lerpValue,
      )!;

      setFloatingCursor(
        FloatingCursorDragState.Update,
        Offset(lerpX, lerpY),
        _lastTextPosition!,
        resetLerpValue: lerpValue,
      );
    }
  }

  // === PRIVATE ===

  void _cacheStateStore(EditorState state) {
    _state = state;
  }

  // Returns the position within the editor closest to the raw cursor offset.
  Offset _calculateBoundedFloatingCursorOffset(
    Offset rawCursorOffset,
    double preferredLineHeight,
  ) {
    var deltaPosition = Offset.zero;
    final topBound = floatingCursorAddedMargin.top;
    final bottomBound = _state.refs.renderer.size.height -
        preferredLineHeight +
        floatingCursorAddedMargin.bottom;
    final leftBound = floatingCursorAddedMargin.left;
    final rightBound =
        _state.refs.renderer.size.width - floatingCursorAddedMargin.right;

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

  // Because the center of the cursor is preferredLineHeight / 2 below the touch origin,
  // but the touch origin is used to determine which line the cursor is on,
  // we need this offset to correctly render and move the cursor.
  Offset _floatingCursorOffset(TextPosition textPosition) {
    final y = _coordinatesService.preferredLineHeight(textPosition) / 2;
    return Offset(0, y);
  }

  // Floating cursor
  void _initFloatingCursorAnimationController() {
    _animationController = AnimationController(
      vsync: _state.refs.widget,
    );
    _animationController.addListener(
      () => onFloatingCursorResetTick(_animationController),
    );
  }
}
