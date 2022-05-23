import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controller/services/editor-controller.dart';
import '../../documents/models/document.dart';
import '../../editor/widgets/visual-editor.dart';
import '../../highlights/models/highlight.model.dart';
import '../../shared/utils/platform.utils.dart';
import 'text-selection-gestures-builder-base.dart';

class TextSelectionGesturesBuilder extends TextSelectionGesturesBuilderBase {
  final VisualEditorState _state;
  final EditorController _controller;
  final List<HighlightM> _hoveredHighlights = [];
  final List<HighlightM> _prevHoveredHighlights = [];

  TextSelectionGesturesBuilder(
    this._state,
    this._controller,
  ) : super(delegate: _state);

  @override
  void onForcePressStart(ForcePressDetails details) {
    super.onForcePressStart(details);

    if (delegate.selectionEnabled && shouldShowSelectionToolbar) {
      editor!.showToolbar();
    }
  }

  @override
  void onForcePressEnd(ForcePressDetails details) {}

  @override
  void onSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_state.widget.config.onSingleLongTapMoveUpdate != null) {
      if (renderEditor != null &&
          _state.widget.config.onSingleLongTapMoveUpdate!(
            details,
            renderEditor!.getPositionForOffset,
          )) {
        return;
      }
    }

    if (!delegate.selectionEnabled) {
      return;
    }

    final _platform = Theme.of(_state.context).platform;

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

  bool _isPositionSelected(TapUpDetails details) {
    if (_state.widget.controller.document.isEmpty()) {
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

  @override
  void onTapDown(TapDownDetails details) {
    if (_state.widget.config.onTapDown != null) {
      if (renderEditor != null &&
          _state.widget.config.onTapDown!(
            details,
            renderEditor!.getPositionForOffset,
          )) {
        return;
      }
    }

    super.onTapDown(details);
  }

  bool isShiftClick(PointerDeviceKind deviceKind) {
    final pressed = RawKeyboard.instance.keysPressed;
    final shiftPressed = pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);

    return deviceKind == PointerDeviceKind.mouse && shiftPressed;
  }

  @override
  void onHover(PointerHoverEvent event) {
    final position = renderEditor!.getPositionForOffset(event.position);

    // Multiple overlapping highlights can be intersected at the same time.
    // Intersecting all highlights avoid "burying" highlights and making
    // them inaccessible.
    // If you need only the highlight hovering highest on top, you'll need to
    // implement custom logic on the client side to select the
    // preferred highlight.
    _hoveredHighlights.clear();

    _controller.highlights.forEach((highlight) {
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
          _controller.hoveredHighlights.add(highlight);
          // _controller.notifyListeners(); // +++ REVIEW
        }

        if (highlight.onHover != null) {
          highlight.onHover!(highlight);
        }
      } else {
        if (wasHovered && highlight.onLeave != null) {
          highlight.onLeave!(highlight);

          // Only once at exit to avoid performance issues
          _controller.hoveredHighlights.remove(highlight);
          // _controller.notifyListeners(); // +++ REVIEW
        }
      }
    });

    _prevHoveredHighlights.clear();
    _prevHoveredHighlights.addAll(_hoveredHighlights);
  }

  @override
  void onSingleTapUp(TapUpDetails details) {
    if (_state.widget.config.onTapUp != null &&
        renderEditor != null &&
        _state.widget.config.onTapUp!(
          details,
          renderEditor!.getPositionForOffset,
        )) {
      return;
    }

    _detectTapOnHighlight(details);

    editor!.hideToolbar();

    try {
      if (delegate.selectionEnabled && !_isPositionSelected(details)) {
        final _platform = Theme.of(_state.context).platform;

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
      _state.requestKeyboard();
    }
  }

  void _detectTapOnHighlight(TapUpDetails details) {
    final position = renderEditor!.getPositionForOffset(details.globalPosition);

    _controller.highlights.forEach((highlight) {
      final start = highlight.textSelection.start;
      final end = highlight.textSelection.end;
      final isTapped = start <= position.offset && position.offset <= end;

      if (isTapped && highlight.onSingleTapUp != null) {
        highlight.onSingleTapUp!(highlight);
      }
    });
  }

  @override
  void onSingleLongTapStart(LongPressStartDetails details) {
    if (_state.widget.config.onSingleLongTapStart != null) {
      if (renderEditor != null &&
          _state.widget.config.onSingleLongTapStart!(
            details,
            renderEditor!.getPositionForOffset,
          )) {
        return;
      }
    }

    if (delegate.selectionEnabled) {
      final _platform = Theme.of(_state.context).platform;

      if (isAppleOS(_platform)) {
        renderEditor!.selectPositionAt(
          from: details.globalPosition,
          cause: SelectionChangedCause.longPress,
        );
      } else {
        renderEditor!.selectWord(SelectionChangedCause.longPress);
        Feedback.forLongPress(_state.context);
      }
    }
  }

  @override
  void onSingleLongTapEnd(LongPressEndDetails details) {
    if (_state.widget.config.onSingleLongTapEnd != null) {
      if (renderEditor != null) {
        if (_state.widget.config.onSingleLongTapEnd!(
          details,
          renderEditor!.getPositionForOffset,
        )) {
          return;
        }

        if (delegate.selectionEnabled) {
          renderEditor!.onSelectionCompleted();
        }
      }
    }

    super.onSingleLongTapEnd(details);
  }
}
