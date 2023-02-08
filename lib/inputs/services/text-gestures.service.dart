import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../doc-tree/services/coordinates.service.dart';
import '../../document/models/history/change-source.enum.dart';
import '../../editor/services/editor.service.dart';
import '../../inputs/services/clipboard.service.dart';
import '../../inputs/services/keyboard.service.dart';
import '../../selection/services/selection-handles.service.dart';
import '../../selection/services/selection.service.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/utils/platform.utils.dart';

// Converts text gestures (tapDown, tapUp) into selection commands via the SelectionService.
// The new selection is cached in the state store and then runBuild() is invoked to update the document widget tree.
// The rendering process for the selection is rendered are explained in `doc-tree.md`, however the short version:
// Once build() is invoked, each EditableTextLine widget then informs there renderer of the selection change.
// Each text line renderer checks if it contains the selection within it's bounds, if so, it triggers a paint() cycle.
// A new paint() cycle will draw the selection rectangles vector data on top of the text.
class TextGesturesService {
  late final EditorService _editorService;
  late final SelectionService _selectionService;
  late final SelectionHandlesService _selectionHandlesService;
  late final KeyboardService _keyboardService;
  late final ClipboardService _clipboardService;
  late final CoordinatesService _coordinatesService;

  final EditorState state;

  TextGesturesService(this.state) {
    _editorService = EditorService(state);
    _selectionService = SelectionService(state);
    _selectionHandlesService = SelectionHandlesService(state);
    _keyboardService = KeyboardService(state);
    _clipboardService = ClipboardService(state);
    _coordinatesService = CoordinatesService(state);
  }

  // === SELECTION ===

  bool selectAllEnabled() {
    return _clipboardService.toolbarOptions().selectAll;
  }

  void updateSelection(TextSelection selection, ChangeSource source) {
    _selectionService.cacheSelectionAndRunBuild(selection, source);
  }

  // === HANDLERS ===

  // Calls the client defined callback.
  // Caches last tap position.
  // Triggers selection toolbar.
  void onTapDown(TapDownDetails event) {
    _callOnTapDown(event);

    state.lastTapDown.setLastTapDown(event.globalPosition);

    // The selection overlay should only be shown when the user is interacting
    // through a touch screen (via either a finger or a stylus).
    // A mouse shouldn't trigger the selection overlay.
    // For backwards-compatibility, we treat a null kind the same as touch.
    final kind = event.kind;
    final isStylusTouchOrNone = kind == null ||
        kind == PointerDeviceKind.touch ||
        kind == PointerDeviceKind.stylus;

    setShouldShowSelectionToolbar(isStylusTouchOrNone);
  }

  // Handles selection changes for several devices types (apple or other).
  // Selection changes will trigger the build (update of the document widget tree).
  // By default, it selects word edge (if selection is enabled).
  // Calls user defined callbacks & requests the keyboard.
  void onSingleTapUp(TapUpDetails event, TargetPlatform platform) {
    _selectionHandlesService.hideToolbar();

    try {
      if (state.config.enableInteractiveSelection &&
          !_isPositionSelected(event)) {
        // Apple
        if (isAppleOS(platform)) {
          switch (event.kind) {
            case PointerDeviceKind.mouse:

            case PointerDeviceKind.stylus:

            case PointerDeviceKind.invertedStylus:
              // Precise devices should place the cursor at a precise position.
              // If `Shift` key is pressed then extend current selection instead.
              if (_isShiftClick(event.kind)) {
                _selectionService.extendSelection(
                  event.globalPosition,
                  cause: SelectionChangedCause.tap,
                );
                _selectionService.callOnSelectionCompleted();
              } else {
                _selectionService.selectPositionAt(
                  from: state.lastTapDown.position!,
                  cause: SelectionChangedCause.tap,
                );
                _selectionService.callOnSelectionCompleted();
              }

              break;

            case PointerDeviceKind.touch:

            case PointerDeviceKind.unknown:
              // On macOS/iOS/iPadOS a touch tap places the cursor at the edge of the word.
              _selectionService.selectWordEdge(SelectionChangedCause.tap);
              _selectionService.callOnSelectionCompleted();
              break;

            case PointerDeviceKind.trackpad:
              // TODO Handle this case
              break;
          }

          // Other OS
        } else {
          _selectionService.selectPositionAt(
            from: state.lastTapDown.position!,
            cause: SelectionChangedCause.tap,
          );

          _selectionService.callOnSelectionCompleted();
        }
      }

      // Request Keyboard
    } finally {
      _keyboardService.requestKeyboard();
    }
  }

  // By default, it controllers as place holder to enable subclass override.
  void onSingleTapCancel() {
    // Subclass should override this method if needed.
  }

  // Selects text position specified in event if selection is enabled.
  // Changes behaviour depending on platform (apple or not).
  // Calls user defined callbacks.
  void onSingleLongTapStart(
    LongPressStartDetails event,
    TargetPlatform platform,
    BuildContext context,
  ) {
    _callOnSingleLongTapStart(event);

    if (state.config.enableInteractiveSelection) {
      if (isAppleOS(platform)) {
        _selectionService.selectPositionAt(
          from: event.globalPosition,
          cause: SelectionChangedCause.longPress,
        );
      } else {
        _selectionService.selectWordsInRange(
          state.lastTapDown.position!,
          null,
          SelectionChangedCause.longPress,
        );
        Feedback.forLongPress(context);
      }
    }
  }

  // Updates the selection location specified in event if selection is enabled.
  // Changes behaviour depending on platform (apple or not).
  // Calls user defined callbacks.
  void onSingleLongTapMoveUpdate(
    LongPressMoveUpdateDetails event,
    TargetPlatform platform,
  ) {
    _callOnSingleLongTapMoveUpdate(event);

    if (!state.config.enableInteractiveSelection) {
      return;
    }

    if (isAppleOS(platform)) {
      _selectionService.selectPositionAt(
        from: event.globalPosition,
        cause: SelectionChangedCause.longPress,
      );
    } else {
      _selectionService.selectWordsInRange(
        event.globalPosition - event.offsetFromOrigin,
        event.globalPosition,
        SelectionChangedCause.longPress,
      );
    }
  }

  // Shows selection toolbar if necessary.
  // Calls user defined callbacks.
  void onSingleLongTapEnd(LongPressEndDetails event) {
    _callOnSingleLongTapEnd(event);

    if (_shouldShowSelectionToolbar) {
      _selectionHandlesService.showToolbar();
    }
  }

  // Selects a word through RenderEditable.selectWord if
  // selectionEnabled and shows buttons if necessary.
  // Displays the selection toolbar.
  void onDoubleTapDown(TapDownDetails event) {
    if (state.config.enableInteractiveSelection) {
      _selectionService.selectWordsInRange(
        state.lastTapDown.position!,
        null,
        SelectionChangedCause.tap,
      );

      // Allow the selection to get updated before trying to bring up toolbars.
      // If double tap happens on an editor that doesn't have focus,
      // selection hasn't been set when the toolbars get added.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_shouldShowSelectionToolbar) {
          _selectionHandlesService.showToolbar();
        }
      });
    }
  }

  // By default, it selects a text position specified in event.
  void onDragSelectionStart(DragStartDetails event) {
    final newSelection = _selectionService.selectPositionAt(
      from: event.globalPosition,
      cause: SelectionChangedCause.drag,
    );

    // Fail safe
    if (newSelection == null) {
      return;
    }

    // Make sure to remember the origin for extend selection.
    state.selection.origin = newSelection;
  }

  // By default, it updates the selection location specified in the provided event objects.
  void onDragSelectionUpdate(
    DragStartDetails startDetails,
    DragUpdateDetails updateDetails,
  ) {
    _selectionService.extendSelection(
      updateDetails.globalPosition,
      cause: SelectionChangedCause.drag,
    );
  }

  // By default, it selects the word at the position of the force press, if selection is enabled.
  void onForcePressStart(ForcePressDetails event) {
    assert(state.config.forcePressEnabled);

    if (!state.config.forcePressEnabled) {
      return;
    }

    setShouldShowSelectionToolbar(true);

    if (state.config.enableInteractiveSelection) {
      _selectionService.selectWordsInRange(
        event.globalPosition,
        null,
        SelectionChangedCause.forcePress,
      );
    }

    if (state.config.enableInteractiveSelection &&
        _shouldShowSelectionToolbar) {
      _selectionHandlesService.showToolbar();
    }
  }

  // By default, it selects words in the range specified in event and shows buttons if it is necessary.
  // This callback is only applicable when force press is enabled.
  // Most likely this code was disabled to enable the floating cursor behavior.
  void onForcePressEnd(ForcePressDetails event) {
    // assert(state.forcePressEnabled);
    // if (!state.forcePressEnabled) {
    //   return;
    // }
    //
    // renderEditor!.selectWordsInRange(
    //   event.globalPosition,
    //   null,
    //   SelectionChangedCause.forcePress,
    // );
    //
    // if (shouldShowSelectionToolbar) {
    //   editor!.showToolbar();
    // }
  }

  // === CALLBACKS ===

  void _callOnTapDown(TapDownDetails event) {
    if (state.config.onTapDown != null) {
      if (state.config.onTapDown!(
        event,
        _coordinatesService.getPositionForOffset,
      )) {
        return;
      }
    }
  }

  void _callOnSingleLongTapStart(LongPressStartDetails event) {
    if (state.config.onSingleLongTapStart != null) {
      if (state.config.onSingleLongTapStart!(
        event,
        _coordinatesService.getPositionForOffset,
      )) {
        return;
      }
    }
  }

  void _callOnSingleLongTapMoveUpdate(LongPressMoveUpdateDetails event) {
    if (state.config.onSingleLongTapMoveUpdate != null) {
      if (state.config.onSingleLongTapMoveUpdate!(
        event,
        _coordinatesService.getPositionForOffset,
      )) {
        return;
      }
    }
  }

  void _callOnSingleLongTapEnd(LongPressEndDetails event) {
    if (state.config.onSingleLongTapEnd != null) {
      if (state.config.onSingleLongTapEnd!(
        event,
        _coordinatesService.getPositionForOffset,
      )) {
        return;
      }

      if (state.config.enableInteractiveSelection) {
        _selectionService.callOnSelectionCompleted();
      }
    }
  }

  // === PRIVATE ===

  bool get _shouldShowSelectionToolbar {
    return state.input.shouldShowSelectionToolbar;
  }

  void setShouldShowSelectionToolbar(bool show) {
    state.input.shouldShowSelectionToolbar = show;
  }

  bool _isPositionSelected(TapUpDetails event) {
    if (state.refs.documentController.isEmpty()) {
      return false;
    }

    final pos = _coordinatesService.getPositionForOffset(
      event.globalPosition,
    );
    final node = _editorService.queryNode(pos.offset);

    if (node.line == null) {
      return false;
    }

    if (node.leaf == null && node.line!.charsNum == 1) {
      updateSelection(
        TextSelection.collapsed(offset: pos.offset),
        ChangeSource.LOCAL,
      );

      return true;
    }

    return false;
  }

  bool _isShiftClick(PointerDeviceKind deviceKind) {
    final pressed = RawKeyboard.instance.keysPressed;
    final shiftPressed = pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);

    return deviceKind == PointerDeviceKind.mouse && shiftPressed;
  }
}
