import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../blocks/models/editable-box-renderer.model.dart';
import '../../cursor/widgets/cursor.dart';
import '../../cursor/widgets/floating-cursor.painter.dart';
import '../../documents/models/document.dart';
import '../../selection/models/drag-text-selection.model.dart';
import '../../selection/services/selection-actions.utils.dart';
import '../../selection/services/text-selection.service.dart';
import '../../selection/services/text-selection.utils.dart';
import '../../selection/state/last-tap-down.state.dart';
import '../models/text-selection-handlers.type.dart';
import '../services/editor-renderer.utils.dart';
import '../services/vertical-caret-movement-run.dart';
import 'editable-container-box-renderer.dart';

// Displays a document as a vertical list of document segments (lines and blocks).
// Children of RenderEditor must be instances of RenderEditableBox.
class EditorRenderer extends EditableContainerBoxRenderer
    with RelayoutWhenSystemFontsChangeMixin
    implements TextLayoutMetrics {
  final _textSelectionUtils = TextSelectionUtils();
  final _editorRendererUtils = EditorRendererUtils();
  final _selectionActionsUtils = SelectionActionsUtils();
  final _textSelectionService = TextSelectionService();
  final _lastTapDownState = LastTapDownState();

  final CursorCont cursorController;
  final bool floatingCursorDisabled;
  final bool scrollable;
  Document document;
  TextSelection selection;
  bool hasFocus;
  LayerLink startHandleLayerLink;
  LayerLink endHandleLayerLink;
  TextSelectionChangedHandler onSelectionChanged;
  TextSelectionCompletedHandler onSelectionCompleted;
  final ValueNotifier<bool> _selectionStartInViewport =
  ValueNotifier<bool>(true);

  EditorRenderer({
    required this.document,
    required TextDirection textDirection,
    required this.hasFocus,
    required this.selection,
    required this.scrollable,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required EdgeInsetsGeometry padding,
    required this.cursorController,
    required this.onSelectionChanged,
    required this.onSelectionCompleted,
    required double scrollBottomInset,
    required this.floatingCursorDisabled,
    ViewportOffset? offset,
    List<RenderEditableBox>? children,
    EdgeInsets floatingCursorAddedMargin =
        const EdgeInsets.fromLTRB(4, 4, 4, 5),
    double? maxContentWidth,
  })  : _extendSelectionOrigin = selection,
        _maxContentWidth = maxContentWidth,
        super(
          children: children,
          container: document.root,
          textDirection: textDirection,
          scrollBottomInset: scrollBottomInset,
          padding: padding,
        );

  ValueListenable<bool> get selectionStartInViewport =>
      _selectionStartInViewport;

  ValueListenable<bool> get selectionEndInViewport => _selectionEndInViewport;
  final ValueNotifier<bool> _selectionEndInViewport = ValueNotifier<bool>(true);

  void _updateSelectionExtentsVisibility(Offset effectiveOffset) {
    final visibleRegion = Offset.zero & size;
    final startPosition = TextPosition(
      offset: selection.start,
      affinity: selection.affinity,
    );
    final startOffset = _getOffsetForCaret(startPosition);
    // TODO(justinmc): https://github.com/flutter/flutter/issues/31495
    // Check if the selection is visible with an approximation because a difference between
    // rounded and unrounded values causes the caret to be reported as having a slightly (< 0.5) negative y offset.
    // This rounding happens in paragraph.cc's layout and TextPainer's _applyFloatingPointHack.
    // Ideally, the rounding mismatch will be fixed and this can be changed to be a strict check instead of an approximation.
    const visibleRegionSlop = 0.5;

    _selectionStartInViewport.value = visibleRegion
        .inflate(visibleRegionSlop)
        .contains(startOffset + effectiveOffset);

    final endPosition = TextPosition(
      offset: selection.end,
      affinity: selection.affinity,
    );
    final endOffset = _getOffsetForCaret(endPosition);

    _selectionEndInViewport.value = visibleRegion
        .inflate(visibleRegionSlop)
        .contains(endOffset + effectiveOffset);
  }

  // Returns offset relative to this at which the caret will be painted given a global TextPosition
  Offset _getOffsetForCaret(TextPosition position) {
    final child = _editorRendererUtils.childAtPosition(position, this);
    final childPosition = child.globalToLocalPosition(position);
    final boxParentData = child.parentData as BoxParentData;
    final localOffsetForCaret = child.getOffsetForCaret(childPosition);
    return boxParentData.offset + localOffsetForCaret;
  }

  void setDocument(Document doc) {
    if (document == doc) {
      return;
    }

    document = doc;
    markNeedsLayout();
  }

  void setHasFocus(bool h) {
    if (hasFocus == h) {
      return;
    }

    hasFocus = h;
    markNeedsSemanticsUpdate();
  }

  Offset get _paintOffset => Offset(0, -(offset?.pixels ?? 0.0));

  ViewportOffset? get offset => _offset;
  ViewportOffset? _offset;

  set offset(ViewportOffset? value) {
    if (_offset == value) {
      return;
    }

    if (attached) {
      _offset?.removeListener(markNeedsPaint);
    }

    _offset = value;

    if (attached) {
      _offset?.addListener(markNeedsPaint);
    }

    markNeedsLayout();
  }

  void setSelection(TextSelection t) {
    if (selection == t) {
      return;
    }

    selection = t;
    markNeedsPaint();

    if (!_shiftPressed && !_isDragging) {
      // Only update extend selection origin if Shift key is not pressed and
      // user is not dragging selection.
      _extendSelectionOrigin = selection;
    }
  }

  bool get _shiftPressed =>
      RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
      RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shiftRight);

  void setStartHandleLayerLink(LayerLink value) {
    if (startHandleLayerLink == value) {
      return;
    }

    startHandleLayerLink = value;
    markNeedsPaint();
  }

  void setEndHandleLayerLink(LayerLink value) {
    if (endHandleLayerLink == value) {
      return;
    }

    endHandleLayerLink = value;
    markNeedsPaint();
  }

  void setScrollBottomInset(double value) {
    if (scrollBottomInset == value) {
      return;
    }

    scrollBottomInset = value;
    markNeedsPaint();
  }

  double? _maxContentWidth;

  set maxContentWidth(double? value) {
    if (_maxContentWidth == value) return;
    _maxContentWidth = value;
    markNeedsLayout();
  }

  // Used on Desktop (mouse and keyboard enabled platforms) as base offset
  // for extending selection, either with combination of `Shift` + Click or by dragging
  TextSelection? _extendSelectionOrigin;

  void handleTapDown(TapDownDetails details) {
    _lastTapDownState.setLastTapDown(details.globalPosition);
  }

  bool _isDragging = false;

  void handleDragStart(DragStartDetails details) {
    _isDragging = true;

    final newSelection = _textSelectionService.selectPositionAt(
      from: details.globalPosition,
      cause: SelectionChangedCause.drag,
      editorRenderer: this,
    );

    if (newSelection == null) return;

    // Make sure to remember the origin for extend selection.
    _extendSelectionOrigin = newSelection;
  }

  void handleDragEnd(DragEndDetails details) {
    _isDragging = false;
    onSelectionCompleted();
  }

  // +++ RESTORE to private OR move to service
  void handleSelectionChange(
    TextSelection nextSelection,
    SelectionChangedCause cause,
  ) {
    final focusingEmpty = nextSelection.baseOffset == 0 &&
        nextSelection.extentOffset == 0 &&
        !hasFocus;

    if (nextSelection == selection &&
        cause != SelectionChangedCause.keyboard &&
        !focusingEmpty) {
      return;
    }

    onSelectionChanged(nextSelection, cause);
  }

  // Extends current selection to the position closest to specified offset.
  void extendSelection(Offset to, {required SelectionChangedCause cause}) {
    // The below logic does not exactly match the native version because
    // we do not allow swapping of base and extent positions.
    assert(_extendSelectionOrigin != null);
    final position = _editorRendererUtils.getPositionForOffset(to, this);

    if (position.offset < _extendSelectionOrigin!.baseOffset) {
      handleSelectionChange(
        TextSelection(
          baseOffset: position.offset,
          extentOffset: _extendSelectionOrigin!.extentOffset,
          affinity: selection.affinity,
        ),
        cause,
      );
    } else if (position.offset > _extendSelectionOrigin!.extentOffset) {
      handleSelectionChange(
        TextSelection(
          baseOffset: _extendSelectionOrigin!.baseOffset,
          extentOffset: position.offset,
          affinity: selection.affinity,
        ),
        cause,
      );
    }
  }

  @override
  void performLayout() {
    assert(() {
      if (!scrollable || !constraints.hasBoundedHeight) return true;

      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          'RenderEditableContainerBox must have '
          'unlimited space along its main axis when it is scrollable.',
        ),
        ErrorDescription(
          'RenderEditableContainerBox does not clip or'
          ' resize its children, so it must be '
          'placed in a parent that does not constrain the main '
          'axis.',
        ),
        ErrorHint(
          'You probably want to put the RenderEditableContainerBox inside a '
          'RenderViewport with a matching main axis or disable the '
          'scrollable property.',
        )
      ]);
    }());

    assert(() {
      if (constraints.hasBoundedWidth) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          'RenderEditableContainerBox must have a bounded'
          ' constraint for its cross axis.',
        ),
        ErrorDescription(
          'RenderEditableContainerBox forces its children to '
          "expand to fit the RenderEditableContainerBox's container, "
          'so it must be placed in a parent that constrains the cross '
          'axis to a finite dimension.',
        ),
      ]);
    }());

    resolvePadding();
    assert(resolvedPadding != null);

    var mainAxisExtent = resolvedPadding!.top;
    var child = firstChild;

    final innerConstraints = BoxConstraints.tightFor(
      width: math.min(
        _maxContentWidth ?? double.infinity,
        constraints.maxWidth,
      ),
    ).deflate(resolvedPadding!);

    final leftOffset = _maxContentWidth == null
        ? 0.0
        : math.max((constraints.maxWidth - _maxContentWidth!) / 2, 0);

    while (child != null) {
      child.layout(innerConstraints, parentUsesSize: true);
      final childParentData = child.parentData as EditableContainerParentData
        ..offset = Offset(resolvedPadding!.left + leftOffset, mainAxisExtent);
      mainAxisExtent += child.size.height;

      assert(child.parentData == childParentData);

      child = childParentData.nextSibling;
    }

    mainAxisExtent += resolvedPadding!.bottom;
    size = constraints.constrain(Size(constraints.maxWidth, mainAxisExtent));

    assert(size.isFinite);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (hasFocus &&
        cursorController.show.value &&
        !cursorController.style.paintAboveText) {
      _paintFloatingCursor(context, offset);
    }

    defaultPaint(context, offset);
    _updateSelectionExtentsVisibility(offset + _paintOffset);
    _paintHandleLayers(
      context,
      _selectionActionsUtils.getEndpointsForSelection(selection, this),
    );

    if (hasFocus &&
        cursorController.show.value &&
        cursorController.style.paintAboveText) {
      _paintFloatingCursor(context, offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  void _paintHandleLayers(
    PaintingContext context,
    List<TextSelectionPoint> endpoints,
  ) {
    var startPoint = endpoints[0].point;
    startPoint = Offset(
      startPoint.dx.clamp(0.0, size.width),
      startPoint.dy.clamp(0.0, size.height),
    );
    context.pushLayer(
      LeaderLayer(link: startHandleLayerLink, offset: startPoint),
      super.paint,
      Offset.zero,
    );

    if (endpoints.length == 2) {
      var endPoint = endpoints[1].point;
      endPoint = Offset(
        endPoint.dx.clamp(0.0, size.width),
        endPoint.dy.clamp(0.0, size.height),
      );
      context.pushLayer(
        LeaderLayer(link: endHandleLayerLink, offset: endPoint),
        super.paint,
        Offset.zero,
      );
    }
  }

  // Returns the y-offset of the editor at which selection is visible.
  // The offset is the distance from the top of the editor and is the minimum
  // from the current scroll position until selection becomes visible.
  // Returns null if selection is already visible.
  // Finds the closest scroll offset that fully reveals the editing cursor.
  // The `scrollOffset` parameter represents current scroll offset in the parent viewport.
  // The `offsetInViewport` parameter represents the editor's vertical offset in the parent viewport.
  // This value should normally be 0.0 if this editor is the only child of the viewport or if it's the topmost child.
  // Otherwise it should be a positive value equal to total height of all siblings of this editor from above it.
  // Returns `null` if the cursor is currently visible.
  double? getOffsetToRevealCursor(
    double viewportHeight,
    double scrollOffset,
    double offsetInViewport,
  ) {
    // Endpoints coordinates represents lower left or lower right corner of the selection.
    // If we want to scroll up to reveal the caret we need to adjust the dy value by the height of the line.
    // We also add a small margin so that the caret is not too close to the edge of the viewport.
    final endpoints = _selectionActionsUtils.getEndpointsForSelection(
      selection,
      this,
    );

    // When we drag the right handle, we should get the last point
    TextSelectionPoint endpoint;

    if (selection.isCollapsed) {
      endpoint = endpoints.first;
    } else {
      if (selection is DragTextSelection) {
        endpoint = (selection as DragTextSelection).first
            ? endpoints.first
            : endpoints.last;
      } else {
        endpoint = endpoints.first;
      }
    }

    // Collapsed selection => caret
    final child = _editorRendererUtils.childAtPosition(selection.extent, this);
    const kMargin = 8.0;

    final caretTop = endpoint.point.dy -
        child.preferredLineHeight(TextPosition(
          offset: selection.extentOffset - child.container.documentOffset,
        )) -
        kMargin +
        offsetInViewport +
        scrollBottomInset;
    final caretBottom =
        endpoint.point.dy + kMargin + offsetInViewport + scrollBottomInset;
    double? dy;

    if (caretTop < scrollOffset) {
      dy = caretTop;
    } else if (caretBottom > scrollOffset + viewportHeight) {
      dy = caretBottom - viewportHeight;
    }

    if (dy == null) {
      return null;
    }

    // Clamping to 0.0 so that the blocks does not jump unnecessarily.
    return math.max(dy, 0);
  }

  // === FLOATING CURSOR ===

  FloatingCursorPainter get _floatingCursorPainter => FloatingCursorPainter(
        floatingCursorRect: floatingCursorRect,
        style: cursorController.style,
      );

  Rect? floatingCursorRect;

  late TextPosition floatingCursorTextPosition;

  void _paintFloatingCursor(PaintingContext context, Offset offset) {
    _floatingCursorPainter.paint(context.canvas);
  }

  EditorVerticalCaretMovementRun startVerticalCaretMovement(
    TextPosition startPosition,
  ) {
    return EditorVerticalCaretMovementRun(this, startPosition);
  }

  @override
  void systemFontsDidChange() {
    super.systemFontsDidChange();
    markNeedsLayout();
  }

  // === TEXT LAYOUT METRICS ===

  @override
  TextSelection getLineAtOffset(TextPosition position) {
    return _textSelectionUtils.getLineAtOffset(position, this);
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    return _textSelectionUtils.getWordBoundary(position, this);
  }

  @override
  TextPosition getTextPositionAbove(TextPosition position) {
    return _textSelectionUtils.getTextPositionAbove(position, this);
  }

  @override
  TextPosition getTextPositionBelow(TextPosition position) {
    return _textSelectionUtils.getTextPositionBelow(position, this);
  }
}
