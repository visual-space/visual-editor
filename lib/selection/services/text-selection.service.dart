import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../controller/services/editor-controller.dart';
import '../../documents/models/document.dart';
import '../../editor/models/editor-state.model.dart';
import '../../editor/widgets/editor-renderer.dart';
import '../../editor/widgets/visual-editor.dart';
import '../../highlights/models/highlight.model.dart';
import '../../shared/utils/platform.utils.dart';

// Implements sensible defaults for many user interactions with a VisualEditor.
class TextSelectionService {
  factory TextSelectionService() => _instance;
  static final _instance = TextSelectionService._privateConstructor();

  TextSelectionService._privateConstructor();

  // The delegate for this TextSelectionGesturesBuilder.
  // The delegate provides the builder with information about what actions can currently be performed on the textfield.
  // Based on this, the builder adds the correct gesture handlers to the gesture detector.
  // final TextSelectionGesturesBuilderDelegate delegate;
  final List<HighlightM> _hoveredHighlights = [];
  final List<HighlightM> _prevHoveredHighlights = [];
  late VisualEditorState state;
  late EditorController controller;

  // Whether to show the selection buttons.
  // It is based on the signal source when a onTapDown is called.
  // Will return true if current onTapDown event is triggered by a touch or a stylus.
  bool _shouldShowSelectionToolbar = true;

  // The State of the VisualEditor for which the builder will provide a TextSelectionGestures.
  EditorState? get editor => state.editableTextKey.currentState;

  // The RenderObject of the VisualEditor for which the builder will provide a TextSelectionGestures.
  RenderEditor? get renderEditor => editor?.renderEditor;

  // TODO REMOVE +++ Temporary method until we can refactor the sharing of the controller and state
  void initState({
    required VisualEditorState state,
    required EditorController controller,
  }) {
    this.state = state;
    this.controller = controller;
  }

  void onHover(PointerHoverEvent event) {
    final position = renderEditor!.getPositionForOffset(event.position);

    // Multiple overlapping highlights can be intersected at the same time.
    // Intersecting all highlights avoid "burying" highlights and making
    // them inaccessible.
    // If you need only the highlight hovering highest on top, you'll need to
    // implement custom logic on the client side to select the
    // preferred highlight.
    _hoveredHighlights.clear();

    controller.highlights.forEach((highlight) {
      final start = highlight.textSelection.start;
      final end = highlight.textSelection.end;
      final isHovered = start <= position.offset && position.offset <= end;
      final wasHovered = _prevHoveredHighlights.contains(highlight);

      if (isHovered) {
        _hoveredHighlights.add(highlight);

        if (!wasHovered && highlight.onEnter != null) {
          highlight.onEnter!(highlight);

          // Only once at enter to avoid performance issues
          // Could be further improved if multiple highlights overlap
          controller.hoveredHighlights.add(highlight);
          // _controller.notifyListeners(); // +++ REVIEW
        }

        if (highlight.onHover != null) {
          highlight.onHover!(highlight);
        }
      } else {
        if (wasHovered && highlight.onLeave != null) {
          highlight.onLeave!(highlight);

          // Only once at exit to avoid performance issues
          controller.hoveredHighlights.remove(highlight);
          // _controller.notifyListeners(); // +++ REVIEW
        }
      }
    });

    _prevHoveredHighlights.clear();
    _prevHoveredHighlights.addAll(_hoveredHighlights);
  }

  // Handler for TextSelectionGestures.onTapDown.
  // By default, it forwards the tap to RenderEditable.handleTapDown and sets shouldShowSelectionToolbar
  // to true if the tap was initiated by a finger or stylus.
  // See also: TextSelectionGestures.onTapDown, which triggers this callback.
  void onTapDown(TapDownDetails details) {
    if (state.widget.config.onTapDown != null) {
      if (renderEditor != null &&
          state.widget.config.onTapDown!(
            details,
            renderEditor!.getPositionForOffset,
          )) {
        return;
      }
    }

    renderEditor!.handleTapDown(details);
    // The selection overlay should only be shown when the user is interacting
    // through a touch screen (via either a finger or a stylus).
    // A mouse shouldn't trigger the selection overlay.
    // For backwards-compatibility, we treat a null kind the same as touch.
    final kind = details.kind;
    _shouldShowSelectionToolbar = kind == null ||
        kind == PointerDeviceKind.touch ||
        kind == PointerDeviceKind.stylus;
  }

  // Handler for TextSelectionGestures.onForcePressStart.
  // By default, it selects the word at the position of the force press, if selection is enabled.
  // This callback is only applicable when force press is enabled.
  // See also: TextSelectionGestures.onForcePressStart, which triggers this callback.
  void onForcePressStart(ForcePressDetails details) {
    assert(state.forcePressEnabled);
    if (!state.forcePressEnabled) {
      return;
    }

    _shouldShowSelectionToolbar = true;
    if (state.selectionEnabled) {
      renderEditor!.selectWordsInRange(
        details.globalPosition,
        null,
        SelectionChangedCause.forcePress,
      );
    }

    if (state.selectionEnabled && _shouldShowSelectionToolbar) {
      editor!.showToolbar();
    }
  }

  // Handler for TextSelectionGestures.onForcePressEnd.
  // By default, it selects words in the range specified in details and shows buttons if it is necessary.
  // This callback is only applicable when force press is enabled.
  // See also: TextSelectionGestures.onForcePressEnd, which triggers this callback.
  void onForcePressEnd(ForcePressDetails details) {
    // +++ REVIEW It appears that this feature was disabled in the original code.
    // No longer working. Maybe it can be restored.
    // assert(state.forcePressEnabled);
    // if (!state.forcePressEnabled) {
    //   return;
    // }
    // renderEditor!.selectWordsInRange(
    //   details.globalPosition,
    //   null,
    //   SelectionChangedCause.forcePress,
    // );
    // if (shouldShowSelectionToolbar) {
    //   editor!.showToolbar();
    // }
  }

  // Handler for TextSelectionGestures.onSingleTapUp.
  // By default, it selects word edge if selection is enabled.
  // See also: TextSelectionGestures.onSingleTapUp, which triggers this callback.
  void onSingleTapUp(TapUpDetails details) {
    if (state.widget.config.onTapUp != null &&
        renderEditor != null &&
        state.widget.config.onTapUp!(
          details,
          renderEditor!.getPositionForOffset,
        )) {
      return;
    }

    _detectTapOnHighlight(details);

    editor!.hideToolbar();

    try {
      if (state.selectionEnabled && !_isPositionSelected(details)) {
        final _platform = Theme.of(state.context).platform;

        if (isAppleOS(_platform)) {
          switch (details.kind) {
            case PointerDeviceKind.mouse:
            case PointerDeviceKind.stylus:
            case PointerDeviceKind.invertedStylus:
              // Precise devices should place the cursor at a precise position.
              // If `Shift` key is pressed then extend current selection instead.
              if (isShiftClick(details.kind)) {
                renderEditor!
                  ..extendSelection(
                    details.globalPosition,
                    cause: SelectionChangedCause.tap,
                  )
                  ..onSelectionCompleted();
              } else {
                renderEditor!
                  ..selectPosition(
                    cause: SelectionChangedCause.tap,
                  )
                  ..onSelectionCompleted();
              }

              break;
            case PointerDeviceKind.touch:
            case PointerDeviceKind.unknown:
              // On macOS/iOS/iPadOS a touch tap places the cursor at the edge of the word.
              renderEditor!
                ..selectWordEdge(SelectionChangedCause.tap)
                ..onSelectionCompleted();
              break;
            case PointerDeviceKind.trackpad:
              // TODO: Handle this case.
              break;
          }
        } else {
          renderEditor!
            ..selectPosition(
              cause: SelectionChangedCause.tap,
            )
            ..onSelectionCompleted();
        }
      }
    } finally {
      state.requestKeyboard();
    }
  }

  // Handler for TextSelectionGestures.onSingleTapCancel.
  // By default, it services as place holder to enable subclass override.
  // See also: TextSelectionGestures.onSingleTapCancel, which triggers this callback.
  void onSingleTapCancel() {
    // Subclass should override this method if needed.
  }

  // Handler for TextSelectionGestures.onSingleLongTapStart.
  // By default, it selects text position specified in details if selection is enabled.
  // See also: TextSelectionGestures.onSingleLongTapStart, which triggers this callback.
  void onSingleLongTapStart(LongPressStartDetails details) {
    if (state.widget.config.onSingleLongTapStart != null) {
      if (renderEditor != null &&
          state.widget.config.onSingleLongTapStart!(
            details,
            renderEditor!.getPositionForOffset,
          )) {
        return;
      }
    }

    if (state.selectionEnabled) {
      final _platform = Theme.of(state.context).platform;

      if (isAppleOS(_platform)) {
        renderEditor!.selectPositionAt(
          from: details.globalPosition,
          cause: SelectionChangedCause.longPress,
        );
      } else {
        renderEditor!.selectWord(SelectionChangedCause.longPress);
        Feedback.forLongPress(state.context);
      }
    }
  }

  // Handler for TextSelectionGestures.onSingleLongTapMoveUpdate
  // By default, it updates the selection location specified in details if selection is enabled.
  // See also: TextSelectionGestures.onSingleLongTapMoveUpdate, which triggers this callback.
  void onSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    if (state.widget.config.onSingleLongTapMoveUpdate != null) {
      if (renderEditor != null &&
          state.widget.config.onSingleLongTapMoveUpdate!(
            details,
            renderEditor!.getPositionForOffset,
          )) {
        return;
      }
    }

    if (!state.selectionEnabled) {
      return;
    }

    final _platform = Theme.of(state.context).platform;

    if (isAppleOS(_platform)) {
      renderEditor!.selectPositionAt(
        from: details.globalPosition,
        cause: SelectionChangedCause.longPress,
      );
    } else {
      renderEditor!.selectWordsInRange(
        details.globalPosition - details.offsetFromOrigin,
        details.globalPosition,
        SelectionChangedCause.longPress,
      );
    }
  }

  // Handler for TextSelectionGestures.onSingleLongTapEnd.
  // By default, it shows buttons if necessary.
  // See also: TextSelectionGestures.onSingleLongTapEnd, which triggers this callback.
  void onSingleLongTapEnd(LongPressEndDetails details) {
    if (state.widget.config.onSingleLongTapEnd != null) {
      if (renderEditor != null) {
        if (state.widget.config.onSingleLongTapEnd!(
          details,
          renderEditor!.getPositionForOffset,
        )) {
          return;
        }

        if (state.selectionEnabled) {
          renderEditor!.onSelectionCompleted();
        }
      }
    }

    if (_shouldShowSelectionToolbar) {
      editor!.showToolbar();
    }
  }

  // Handler for TextSelectionGestures.onDoubleTapDown.
  // By default, it selects a word through RenderEditable.selectWord if  selectionEnabled and shows buttons if necessary.
  // See also: TextSelectionGestures.onDoubleTapDown, which triggers this callback.
  void onDoubleTapDown(TapDownDetails details) {
    if (state.selectionEnabled) {
      renderEditor!.selectWord(SelectionChangedCause.tap);

      // Allow the selection to get updated before trying to bring up toolbars.
      // If double tap happens on an editor that doesn't have focus,
      // selection hasn't been set when the toolbars get added.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_shouldShowSelectionToolbar) {
          editor!.showToolbar();
        }
      });
    }
  }

  // Handler for TextSelectionGestures.onDragSelectionStart.
  // By default, it selects a text position specified in details.
  // See also:  TextSelectionGestures.onDragSelectionStart, which triggers this callback.
  void onDragSelectionStart(DragStartDetails details) {
    renderEditor!.handleDragStart(details);
  }

  // Handler for TextSelectionGestures.onDragSelectionUpdate.
  // By default, it updates the selection location specified in the provided details objects.
  // See also: TextSelectionGestures.onDragSelectionUpdate, which triggers this callback.
  void onDragSelectionUpdate(
      DragStartDetails startDetails, DragUpdateDetails updateDetails) {
    renderEditor!.extendSelection(updateDetails.globalPosition,
        cause: SelectionChangedCause.drag);
  }

  // Handler for TextSelectionGestures.onDragSelectionEnd.
  // By default, it services as place holder to enable subclass override.
  // See also: TextSelectionGestures.onDragSelectionEnd, which triggers this callback.
  void onDragSelectionEnd(DragEndDetails details) {
    renderEditor!.handleDragEnd(details);
  }

  // === UTILS ===

  bool _isPositionSelected(TapUpDetails details) {
    if (state.widget.controller.document.isEmpty()) {
      return false;
    }

    final pos = renderEditor!.getPositionForOffset(details.globalPosition);
    final result =
        editor!.widget.controller.document.querySegmentLeafNode(pos.offset);
    final line = result.item1;

    if (line == null) {
      return false;
    }

    final segmentLeaf = result.item2;

    if (segmentLeaf == null && line.length == 1) {
      editor!.widget.controller.updateSelection(
          TextSelection.collapsed(offset: pos.offset), ChangeSource.LOCAL);
      return true;
    }

    return false;
  }

  bool isShiftClick(PointerDeviceKind deviceKind) {
    final pressed = RawKeyboard.instance.keysPressed;
    final shiftPressed = pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);

    return deviceKind == PointerDeviceKind.mouse && shiftPressed;
  }

  void _detectTapOnHighlight(TapUpDetails details) {
    final position = renderEditor!.getPositionForOffset(details.globalPosition);

    controller.highlights.forEach((highlight) {
      final start = highlight.textSelection.start;
      final end = highlight.textSelection.end;
      final isTapped = start <= position.offset && position.offset <= end;

      if (isTapped && highlight.onSingleTapUp != null) {
        highlight.onSingleTapUp!(highlight);
      }
    });
  }
}
