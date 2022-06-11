import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../controller/state/editor-controller.state.dart';
import '../../controller/state/scroll-controller.state.dart';
import '../../selection/models/drag-text-selection.model.dart';
import '../../selection/services/selection-actions.utils.dart';
import '../state/editor-config.state.dart';
import '../state/editor-renderer.state.dart';
import '../state/editor-state-widget.state.dart';
import '../state/scroll-controller-animation.state.dart';
import 'lines-blocks.service.dart';

class CaretService {
  final _linesBlocksService = LinesBlocksService();
  final _editorRendererState = EditorRendererState();
  final _editorControllerState = EditorControllerState();
  final _selectionActionsUtils = SelectionActionsUtils();
  final _scrollControllerState = ScrollControllerState();
  final _editorConfigState = EditorConfigState();
  final _editorStateWidgetState = EditorStateWidgetState();
  final _scrollControllerAnimationState = ScrollControllerAnimationState();

  bool _showCaretOnScreenScheduled = false;

  static final _instance = CaretService._privateConstructor();

  factory CaretService() => _instance;

  CaretService._privateConstructor();

  void showCaretOnScreen() {
    if (!_editorConfigState.config.showCursor || _showCaretOnScreenScheduled) {
      return;
    }

    _showCaretOnScreenScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_editorConfigState.config.scrollable ||
          _scrollControllerState.controller.hasClients) {
        _showCaretOnScreenScheduled = false;
        final renderer = _editorRendererState.renderer;

        if (!_editorStateWidgetState.editor.mounted) {
          return;
        }

        final viewport = RenderAbstractViewport.of(renderer);
        final editorOffset = renderer.localToGlobal(
          const Offset(0, 0),
          ancestor: viewport,
        );
        final offsetInViewport =
            _scrollControllerState.controller.offset + editorOffset.dy;

        final offset = getOffsetToRevealCursor(
          _scrollControllerState.controller.position.viewportDimension,
          _scrollControllerState.controller.offset,
          offsetInViewport,
        );

        if (offset != null) {
          if (_scrollControllerAnimationState.disabled) {
            _scrollControllerAnimationState.disableAnimationOnce(false);
            return;
          }

          _scrollControllerState.controller.animateTo(
            math.min(
              offset,
              _scrollControllerState.controller.position.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 100),
            curve: Curves.fastOutSlowIn,
          );
        }
      }
    });
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
    final selection = _editorControllerState.controller.selection;
    // Endpoints coordinates represents lower left or lower right corner of the selection.
    // If we want to scroll up to reveal the caret we need to adjust the dy value by the height of the line.
    // We also add a small margin so that the caret is not too close to the edge of the viewport.
    final endpoints = _selectionActionsUtils.getEndpointsForSelection(
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
    final child = _linesBlocksService.childAtPosition(selection.extent);
    const margin = 8.0;

    final offset =
        margin + offsetInViewport + _editorConfigState.config.scrollBottomInset;

    final lineHeight = child.preferredLineHeight(
      TextPosition(
        offset: selection.extentOffset - child.container.documentOffset,
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

    // Clamping to 0.0 so that the blocks does not jump unnecessarily.
    return math.max(dy, 0);
  }
}
