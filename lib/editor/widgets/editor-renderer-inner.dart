import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../blocks/models/editable-box-renderer.model.dart';
import '../../controller/state/editor-controller.state.dart';
import '../../cursor/state/cursor-controller.state.dart';
import '../../cursor/widgets/floating-cursor.painter.dart';
import '../../documents/models/document.model.dart';
import '../../selection/services/selection-actions.utils.dart';
import '../../selection/services/text-selection.utils.dart';
import '../../selection/state/selection-layers.state.dart';
import '../controllers/vertical-caret-movement-run.controller.dart';
import '../services/lines-blocks.service.dart';
import '../state/editor-config.state.dart';
import '../state/editor-renderer.state.dart';
import '../state/extend-selection.state.dart';
import '../state/focus-node.state.dart';
import 'editable-container-box-renderer.dart';

// Displays a document as a vertical list of document segments (lines and blocks).
// Children of RenderEditor must be instances of RenderEditableBox.
class EditorRendererInner extends EditableContainerBoxRenderer
    with RelayoutWhenSystemFontsChangeMixin
    implements TextLayoutMetrics {
  final _editorConfigState = EditorConfigState();
  final _editorControllerState = EditorControllerState();
  final _cursorControllerState = CursorControllerState();
  final _textSelectionUtils = TextSelectionUtils();
  final _linesBlocksService = LinesBlocksService();
  final _editorRendererState = EditorRendererState();
  final _selectionActionsUtils = SelectionActionsUtils();
  final _focusNodeState = FocusNodeState();
  final _selectionLayersState = SelectionLayersState();
  final _extendSelectionState = ExtendSelectionState();

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
      );

  EditorRendererInner({
    required this.document, // +++ Move to service
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
    // +++ MOVE to controller
    _extendSelectionState.setOrigin(
      _editorControllerState.controller.selection,
    );
    _editorRendererState.setRenderer(this);
    super.padding = _editorConfigState.config.padding;
  }

  @override
  void performLayout() {
    assert(() {
      if (!_editorConfigState.config.scrollable ||
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

    final maxContentWidth = _editorConfigState.config.maxContentWidth;
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
    if (_focusNodeState.node.hasFocus &&
        _cursorControllerState.controller.show.value &&
        !_cursorControllerState.controller.style.paintAboveText) {
      _paintFloatingCursor(context, offset);
    }

    final selection = _editorControllerState.controller.selection;
    final selectionEndpoints = _selectionActionsUtils.getEndpointsForSelection(
      selection,
    );

    defaultPaint(context, offset);
    _updateSelectionExtentsVisibility(offset + _paintOffset);
    _paintHandleLayers(context, selectionEndpoints);

    if (_focusNodeState.node.hasFocus &&
        _cursorControllerState.controller.show.value &&
        _cursorControllerState.controller.style.paintAboveText) {
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
        link: _selectionLayersState.startHandleLayerLink,
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
          link: _selectionLayersState.endHandleLayerLink,
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
    final selection = _editorControllerState.controller.selection;
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
    final child = _linesBlocksService.childAtPosition(position);
    final childPosition = child.globalToLocalPosition(position);
    final boxParentData = child.parentData as BoxParentData;
    final localOffsetForCaret = child.getOffsetForCaret(childPosition);

    return boxParentData.offset + localOffsetForCaret;
  }
}
