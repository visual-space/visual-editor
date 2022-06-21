import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../blocks/services/lines-blocks.service.dart';
import '../../controller/state/scroll-controller.state.dart';
import '../../editor/state/editor-renderer.state.dart';

class CursorService {
  static final _scrollControllerState = ScrollControllerState();
  static final _editorRendererState = EditorRendererState();
  static final _linesBlocksService = LinesBlocksService();
  static final _instance = CursorService._privateConstructor();

  factory CursorService() => _instance;

  CursorService._privateConstructor();

  // Scroll the editor until the content caret is visible
  // Usually triggered by moving the caret when off screen.
  void bringIntoView(TextPosition position) {
    final localRect = getLocalRectForCaret(position);
    final targetOffset = _getOffsetToRevealCaret(
      localRect,
      position,
    );

    if (_scrollControllerState.controller.hasClients) {
      _scrollControllerState.controller.jumpTo(targetOffset.offset);
    }

    _editorRendererState.renderer.showOnScreen(
      rect: targetOffset.rect,
    );
  }

  Rect getLocalRectForCaret(TextPosition position) {
    final targetChild = _linesBlocksService.childAtPosition(position);
    final localPosition = targetChild.globalToLocalPosition(position);
    final childLocalRect = targetChild.getLocalRectForCaret(localPosition);
    final boxParentData = targetChild.parentData as BoxParentData;

    return childLocalRect.shift(Offset(0, boxParentData.offset.dy));
  }

  // === PRIVATE ===

  // Finds the closest scroll offset to the current scroll offset that fully reveals the given caret rect.
  // If the given rect's main axis extent is too large to be fully revealed in `renderEditable`,
  // it will be centered along the main axis.
  // If this is a multiline VisualEditor (which means the Editable can only  scroll vertically),
  // the given rect's height will first be extended to match `renderEditable.preferredLineHeight`,
  // before the target scroll offset is calculated.
  RevealedOffset _getOffsetToRevealCaret(
    Rect rect,
    TextPosition position,
  ) {
    if (_isConnectedAndAllowedToSelfScroll()) {
      return RevealedOffset(
        offset: _scrollControllerState.controller.offset,
        rect: rect,
      );
    }

    final editableSize = _editorRendererState.renderer.size;
    final double additionalOffset;
    final Offset unitOffset;

    // The caret is vertically centered within the line. Expand the caret's
    // height so that it spans the line because we're going to ensure that the entire expanded caret is scrolled into view.
    final expandedRect = Rect.fromCenter(
      center: rect.center,
      width: rect.width,
      height: math.max(
        rect.height,
        _linesBlocksService.preferredLineHeight(position),
      ),
    );

    additionalOffset = expandedRect.height >= editableSize.height
        ? editableSize.height / 2 - expandedRect.center.dy
        : 0.0.clamp(
            expandedRect.bottom - editableSize.height,
            expandedRect.top,
          );

    unitOffset = const Offset(0, 1);

    // No over-scrolling when encountering tall fonts/scripts that extend past the ascent.
    var targetOffset = additionalOffset;

    if (_scrollControllerState.controller.hasClients) {
      targetOffset =
          (additionalOffset + _scrollControllerState.controller.offset).clamp(
        _scrollControllerState.controller.position.minScrollExtent,
        _scrollControllerState.controller.position.maxScrollExtent,
      );
    }

    final offsetDelta = (_scrollControllerState.controller.hasClients
            ? _scrollControllerState.controller.offset
            : 0) -
        targetOffset;

    return RevealedOffset(
      rect: rect.shift(unitOffset * offsetDelta),
      offset: targetOffset,
    );
  }

  bool _isConnectedAndAllowedToSelfScroll() {
    return _scrollControllerState.controller.hasClients &&
        !_scrollControllerState.controller.position.allowImplicitScrolling;
  }
}
