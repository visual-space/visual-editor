import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../doc-tree/services/coordinates.service.dart';
import '../../document/services/nodes/node.utils.dart';
import '../../selection/models/drag-text-selection.model.dart';
import '../../selection/services/selection-handles.service.dart';
import '../../shared/state/editor.state.dart';

// Handles displaying the caret.
class CaretService {
  late final CoordinatesService _coordinatesService;
  late final SelectionHandlesService _selectionHandlesService;
  final _nodeUtils = NodeUtils();

  final EditorState state;

  CaretService(this.state) {
    _coordinatesService = CoordinatesService(state);
    _selectionHandlesService = SelectionHandlesService(state);
  }

  // Scroll the editor to show the caret
  void showCaretOnScreen() {
    final readOnly = state.config.readOnly;
    final isScrollable = state.config.scrollable;
    final hasClients = state.refs.scrollController.hasClients;

    if (readOnly || state.cursor.showCaretOnScreenScheduled) {
      return;
    }

    state.cursor.showCaretOnScreenScheduled = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (isScrollable || hasClients) {
        state.cursor.showCaretOnScreenScheduled = false;

        if (!state.refs.widget.mounted) {
          return;
        }

        final renderer = state.refs.renderer;
        final editorRenderer = RenderAbstractViewport.of(renderer);
        final offsetInsideEditor = renderer.localToGlobal(
          const Offset(0, 0),
          ancestor: editorRenderer,
        );
        final offsetInViewport =
            state.refs.scrollController.offset + offsetInsideEditor.dy;

        final offset = getOffsetToRevealCursor(
          state.refs.scrollController.position.viewportDimension,
          state.refs.scrollController.offset,
          offsetInViewport,
        );

        if (offset != null) {
          if (state.scrollAnimation.disabled) {
            state.scrollAnimation.disabled = false;
            return;
          }

          state.refs.scrollController.animateTo(
            math.min(
              offset,
              state.refs.scrollController.position.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 100),
            curve: Curves.fastOutSlowIn,
          );
        }
      }
    });
  }

  // Scroll the editor until the content caret is visible
  // Usually triggered by moving the caret when off screen.
  void bringIntoView(TextPosition position) {
    final localRect = getLocalRectForCaret(position);
    final targetOffset = _getOffsetToRevealCaret(localRect, position);

    if (state.refs.scrollController.hasClients) {
      state.refs.scrollController.jumpTo(targetOffset.offset);
    }

    state.refs.renderer.showOnScreen(
      rect: targetOffset.rect,
    );
  }

  Rect getLocalRectForCaret(TextPosition position) {
    final targetChild = _coordinatesService.childAtPosition(position);
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
  RevealedOffset _getOffsetToRevealCaret(Rect rect, TextPosition position) {
    if (_isConnectedAndAllowedToSelfScroll()) {
      return RevealedOffset(
        offset: state.refs.scrollController.offset,
        rect: rect,
      );
    }

    final editableSize = state.refs.renderer.size;
    final double additionalOffset;
    final Offset unitOffset;

    // The caret is vertically centered within the line. Expand the caret's
    // height so that it spans the line because we're going to ensure that the entire expanded caret is scrolled into view.
    final expandedRect = Rect.fromCenter(
      center: rect.center,
      width: rect.width,
      height: math.max(
        rect.height,
        _coordinatesService.preferredLineHeight(position),
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

    if (state.refs.scrollController.hasClients) {
      targetOffset =
          (additionalOffset + state.refs.scrollController.offset).clamp(
        state.refs.scrollController.position.minScrollExtent,
        state.refs.scrollController.position.maxScrollExtent,
      );
    }

    final offsetDelta = (state.refs.scrollController.hasClients
            ? state.refs.scrollController.offset
            : 0) -
        targetOffset;

    return RevealedOffset(
      rect: rect.shift(unitOffset * offsetDelta),
      offset: targetOffset,
    );
  }

  bool _isConnectedAndAllowedToSelfScroll() {
    return state.refs.scrollController.hasClients &&
        !state.refs.scrollController.position.allowImplicitScrolling;
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
    final selection = state.selection.selection;
    // Endpoints coordinates represents lower left or lower right corner of the selection.
    // If we want to scroll up to reveal the caret we need to adjust the dy value by the height of the line.
    // We also add a small margin so that the caret is not too close to the edge of the viewport.
    final endpoints = _selectionHandlesService.getEndpointsForSelection(
      selection,
    );

    // When we drag the right handle, we should get the last point
    TextSelectionPoint endpoint;

    if (selection.isCollapsed) {
      endpoint = endpoints.first;
    } else {
      if (selection is DragTextSelection) {
        endpoint = selection.first ? endpoints.first : endpoints.last;
      } else {
        endpoint = endpoints.first;
      }
    }

    // Collapsed selection => caret
    final child = _coordinatesService.childAtPosition(selection.extent);
    const margin = 8.0;

    final offset = margin + offsetInViewport + state.config.scrollBottomInset;

    final lineHeight = child.preferredLineHeight(
      TextPosition(
        offset: selection.extentOffset - _nodeUtils.getDocumentOffset(child.container),
      ),
    );

    final caretTop = endpoint.point.dy - lineHeight - offset;
    final caretBottom = endpoint.point.dy + offset;
    double? dy;

    if (caretTop < scrollOffset) {
      dy = caretTop;
    } else if (caretBottom > scrollOffset + viewportHeight) {
      dy = caretBottom - viewportHeight;
    }

    if (dy == null) {
      return null;
    }

    // Clamping to 0.0 so that the doc-tree does not jump unnecessarily.
    return math.max(dy, 0);
  }
}
