import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../blocks/services/lines-blocks.service.dart';
import '../../cursor/widgets/floating-cursor.painter.dart';
import '../../documents/models/document.model.dart';
import '../../selection/services/selection-actions.service.dart';
import '../../selection/services/text-selection.utils.dart';
import '../../shared/models/editable-box-renderer.model.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/widgets/multiline-text-area-renderer.dart';
import '../controllers/vertical-caret-movement-run.controller.dart';

// Displays a document as a vertical list of document segments (lines and blocks).
// Children of RenderEditor must be instances of RenderEditableBox.
// Also renders the floating cursor (cursor displayed when long tapping on mobile and dragging the cursor).
class EditorRendererInner extends MultilineTextAreaRenderer
    with RelayoutWhenSystemFontsChangeMixin
    implements TextLayoutMetrics {
  final _textSelectionUtils = TextSelectionUtils();
  final _linesBlocksService = LinesBlocksService();
  final _selectionActionsService = SelectionActionsService();

  DocumentM document;
  Rect? floatingCursorRect;
  late TextPosition floatingCursorTextPosition;

  final ValueNotifier<bool> _selectionStartInViewport =
      ValueNotifier<bool>(true);

  ValueListenable<bool> get selectionStartInViewport =>
      _selectionStartInViewport;

  ValueListenable<bool> get selectionEndInViewport => _selectionEndInViewport;
  final ValueNotifier<bool> _selectionEndInViewport = ValueNotifier<bool>(true);

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

  FloatingCursorPainter get _floatingCursorPainter => FloatingCursorPainter(
        floatingCursorRect: floatingCursorRect,
        state: _state,
      );

  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  void setState(EditorState state) {
    _state = state;
  }

  EditorRendererInner({
    required this.document,
    required EditorState state,
    required TextDirection textDirection,
    ViewportOffset? offset,
    List<EditableBoxRenderer>? children,
    EdgeInsets floatingCursorAddedMargin =
        const EdgeInsets.fromLTRB(4, 4, 4, 5),
  }) : super(
          children: children,
          container: document.root,
          textDirection: textDirection,
        ) {
    setState(state);
    state.refs.setRenderer(this);
    super.padding = state.editorConfig.config.padding;
  }

  @override
  void performLayout() {
    assert(() {
      if (!_state.editorConfig.config.scrollable ||
          !constraints.hasBoundedHeight) {
        return true;
      }

      throw FlutterError.fromParts(
        <DiagnosticsNode>[
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
        ],
      );
    }());

    assert(() {
      if (constraints.hasBoundedWidth) {
        return true;
      }

      throw FlutterError.fromParts(
        <DiagnosticsNode>[
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
        ],
      );
    }());

    resolvePadding();
    assert(resolvedPadding != null);

    var mainAxisExtent = resolvedPadding!.top;
    var child = firstChild;

    final maxContentWidth = _state.editorConfig.config.maxContentWidth;
    final innerConstraints = BoxConstraints.tightFor(
      width: math.min(
        maxContentWidth ?? double.infinity,
        constraints.maxWidth,
      ),
    ).deflate(resolvedPadding!);

    final leftOffset = maxContentWidth == null
        ? 0.0
        : math.max((constraints.maxWidth - maxContentWidth) / 2, 0);

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
    if (_state.refs.focusNode.hasFocus &&
        _state.refs.cursorController.show.value &&
        !_state.refs.cursorController.style.paintAboveText) {
      _paintFloatingCursor(context, offset);
    }

    final selection = _state.refs.editorController.selection;
    final selectionEndpoints =
        _selectionActionsService.getEndpointsForSelection(
      selection,
      _state,
    );

    defaultPaint(context, offset);
    _updateSelectionExtentsVisibility(offset + _paintOffset);
    _paintHandleLayers(context, selectionEndpoints);

    if (_state.refs.focusNode.hasFocus &&
        _state.refs.cursorController.show.value &&
        _state.refs.cursorController.style.paintAboveText) {
      _paintFloatingCursor(context, offset);
    }
  }

  @override
  bool hitTestChildren(
    BoxHitTestResult result, {
    required Offset position,
  }) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void systemFontsDidChange() {
    super.systemFontsDidChange();
    markNeedsLayout();
  }

  // === TEXT LAYOUT METRICS ===

  @override
  TextSelection getLineAtOffset(TextPosition position) {
    return _textSelectionUtils.getLineAtOffset(position, this, _state);
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    return _textSelectionUtils.getWordBoundary(position, this, _state);
  }

  @override
  TextPosition getTextPositionAbove(TextPosition position) {
    return _textSelectionUtils.getTextPositionAbove(position, this, _state);
  }

  @override
  TextPosition getTextPositionBelow(TextPosition position) {
    return _textSelectionUtils.getTextPositionBelow(position, this, _state);
  }

  VerticalCaretMovementRunController startVerticalCaretMovement(
    TextPosition startPosition,
  ) =>
      VerticalCaretMovementRunController(this, startPosition);

  // === PRIVATE ===

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
      LeaderLayer(
        link: _state.selectionLayers.startHandleLayerLink,
        offset: startPoint,
      ),
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
        LeaderLayer(
          link: _state.selectionLayers.endHandleLayerLink,
          offset: endPoint,
        ),
        super.paint,
        Offset.zero,
      );
    }
  }

  void _paintFloatingCursor(PaintingContext context, Offset offset) {
    _floatingCursorPainter.paint(context.canvas);
  }

  void _updateSelectionExtentsVisibility(Offset effectiveOffset) {
    final selection = _state.refs.editorController.selection;
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
    final child = _linesBlocksService.childAtPosition(position, _state);
    final childPosition = child.globalToLocalPosition(position);
    final boxParentData = child.parentData as BoxParentData;
    final localOffsetForCaret = child.getOffsetForCaret(childPosition);

    return boxParentData.offset + localOffsetForCaret;
  }
}
