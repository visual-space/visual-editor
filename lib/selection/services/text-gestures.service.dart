import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../blocks/services/lines-blocks.service.dart';
import '../../documents/models/change-source.enum.dart';
import '../../inputs/services/clipboard.service.dart';
import '../../inputs/services/keyboard.service.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/utils/platform.utils.dart';
import 'selection-actions.service.dart';
import 'text-selection.service.dart';

// How text selection works:
// Controls the selection of text after tapDown and tapUp events.
// Once the selection range is known it's than passed to the state store.
// Starting and updating the selection is triggered from the TextGestures widget and
// parsed by this service which in turn calls TextSelectionService.
// Then the controller.updateSelection() is called which triggers the refreshEditor() which triggers a build() in main.
// EditableTextLine widget then calls on the renderer object methods to update information.
// If the renderer callbacks notice that the selection is changed and within it's bounds then it triggers a paint() cycle.
// A new paint() cycle will "render" the selection rectangles vector data on top of the text.
class TextGesturesService {
  final _textSelectionService = TextSelectionService();
  final _selectionActionsService = SelectionActionsService();
  final _keyboardService = KeyboardService();
  final _clipboardService = ClipboardService();
  final _linesBlocksService = LinesBlocksService();

  // Whether to show the selection buttons.
  // It is based on the signal source when a onTapDown is called.
  // Will return true if current onTapDown event is triggered by a touch or a stylus.
  bool _shouldShowSelectionToolbar = true;

  factory TextGesturesService() => _instance;

  static final _instance = TextGesturesService._privateConstructor();

  TextGesturesService._privateConstructor();

  bool selectAllEnabled(EditorState state) =>
      _clipboardService.toolbarOptions(state).selectAll;

  void updateSelection(
    TextSelection textSelection,
    ChangeSource source,
    EditorState state,
  ) {
    state.refs.editorController.updateSelection(textSelection, source);
  }

  // === HANDLERS ===

  // By default, it forwards the tap to RenderEditable.handleTapDown and sets shouldShowSelectionToolbar
  // to true if the tap was initiated by a finger or stylus.
  void onTapDown(TapDownDetails details, EditorState state) {
    if (state.editorConfig.config.onTapDown != null) {
      if (state.editorConfig.config.onTapDown!(
        details,
        _linesBlocksService.getPositionForOffset,
      )) {
        return;
      }
    }

    state.lastTapDown.setLastTapDown(details.globalPosition);

    // The selection overlay should only be shown when the user is interacting
    // through a touch screen (via either a finger or a stylus).
    // A mouse shouldn't trigger the selection overlay.
    // For backwards-compatibility, we treat a null kind the same as touch.
    final kind = details.kind;
    _shouldShowSelectionToolbar = kind == null ||
        kind == PointerDeviceKind.touch ||
        kind == PointerDeviceKind.stylus;
  }

  // By default, it selects the word at the position of the force press, if selection is enabled.
  void onForcePressStart(
    ForcePressDetails details,
    EditorState state,
  ) {
    assert(state.editorConfig.config.forcePressEnabled);

    if (!state.editorConfig.config.forcePressEnabled) {
      return;
    }

    _shouldShowSelectionToolbar = true;
    if (state.editorConfig.config.enableInteractiveSelection) {
      _textSelectionService.selectWordsInRange(
        details.globalPosition,
        null,
        SelectionChangedCause.forcePress,
        state,
      );
    }

    if (state.editorConfig.config.enableInteractiveSelection &&
        _shouldShowSelectionToolbar) {
      _selectionActionsService.showToolbar(state);
    }
  }

  // By default, it selects words in the range specified in details and shows buttons if it is necessary.
  // This callback is only applicable when force press is enabled.
  // Most likely this code was disabled to enable the floating cursor behavior.
  void onForcePressEnd(ForcePressDetails details) {
    // assert(state.forcePressEnabled);
    // if (!state.forcePressEnabled) {
    //   return;
    // }
    //
    // renderEditor!.selectWordsInRange(
    //   details.globalPosition,
    //   null,
    //   SelectionChangedCause.forcePress,
    // );
    //
    // if (shouldShowSelectionToolbar) {
    //   editor!.showToolbar();
    // }
  }

  // By default, it selects word edge if selection is enabled.
  void onSingleTapUp(
    TapUpDetails details,
    TargetPlatform platform,
    EditorState state,
  ) {
    if (state.editorConfig.config.onTapUp != null &&
        state.editorConfig.config.onTapUp!(
          details,
          _linesBlocksService.getPositionForOffset,
        )) {
      return;
    }

    _selectionActionsService.hideToolbar(state);

    try {
      if (state.editorConfig.config.enableInteractiveSelection &&
          !_isPositionSelected(details, state)) {
        if (isAppleOS(platform)) {
          switch (details.kind) {
            case PointerDeviceKind.mouse:

            case PointerDeviceKind.stylus:

            case PointerDeviceKind.invertedStylus:
              // Precise devices should place the cursor at a precise position.
              // If `Shift` key is pressed then extend current selection instead.
              if (_isShiftClick(details.kind)) {
                _textSelectionService.extendSelection(
                  details.globalPosition,
                  state,
                  cause: SelectionChangedCause.tap,
                );
                _textSelectionService.onSelectionCompleted(state);
              } else {
                _textSelectionService.selectPositionAt(
                  from: state.lastTapDown.position!,
                  cause: SelectionChangedCause.tap,
                  state: state,
                );
                _textSelectionService.onSelectionCompleted(state);
              }

              break;

            case PointerDeviceKind.touch:

            case PointerDeviceKind.unknown:
              // On macOS/iOS/iPadOS a touch tap places the cursor at the edge of the word.
              _textSelectionService.selectWordEdge(
                SelectionChangedCause.tap,
                state,
              );
              _textSelectionService.onSelectionCompleted(state);
              break;

            case PointerDeviceKind.trackpad:
              // TODO Handle this case
              break;
          }
        } else {
          _textSelectionService.selectPositionAt(
            from: state.lastTapDown.position!,
            cause: SelectionChangedCause.tap,
            state: state,
          );

          _textSelectionService.onSelectionCompleted(state);
        }
      }
    } finally {
      _keyboardService.requestKeyboard(state);
    }
  }

  // By default, it controllers as place holder to enable subclass override.
  void onSingleTapCancel() {
    // Subclass should override this method if needed.
  }

  // By default, it selects text position specified in details if selection is enabled.
  void onSingleLongTapStart(
    LongPressStartDetails details,
    TargetPlatform platform,
    BuildContext context,
    EditorState state,
  ) {
    if (state.editorConfig.config.onSingleLongTapStart != null) {
      if (state.editorConfig.config.onSingleLongTapStart!(
        details,
        _linesBlocksService.getPositionForOffset,
      )) {
        return;
      }
    }

    if (state.editorConfig.config.enableInteractiveSelection) {
      if (isAppleOS(platform)) {
        _textSelectionService.selectPositionAt(
          from: details.globalPosition,
          cause: SelectionChangedCause.longPress,
          state: state,
        );
      } else {
        _textSelectionService.selectWordsInRange(
          state.lastTapDown.position!,
          null,
          SelectionChangedCause.longPress,
          state,
        );
        Feedback.forLongPress(context);
      }
    }
  }

  // By default, it updates the selection location specified in details if selection is enabled.
  void onSingleLongTapMoveUpdate(
    LongPressMoveUpdateDetails details,
    TargetPlatform platform,
    EditorState state,
  ) {
    if (state.editorConfig.config.onSingleLongTapMoveUpdate != null) {
      if (state.editorConfig.config.onSingleLongTapMoveUpdate!(
        details,
        _linesBlocksService.getPositionForOffset,
      )) {
        return;
      }
    }

    if (!state.editorConfig.config.enableInteractiveSelection) {
      return;
    }

    if (isAppleOS(platform)) {
      _textSelectionService.selectPositionAt(
        from: details.globalPosition,
        cause: SelectionChangedCause.longPress,
        state: state,
      );
    } else {
      _textSelectionService.selectWordsInRange(
        details.globalPosition - details.offsetFromOrigin,
        details.globalPosition,
        SelectionChangedCause.longPress,
        state,
      );
    }
  }

  // By default, it shows buttons if necessary.
  void onSingleLongTapEnd(LongPressEndDetails details, EditorState state) {
    if (state.editorConfig.config.onSingleLongTapEnd != null) {
      if (state.editorConfig.config.onSingleLongTapEnd!(
        details,
        _linesBlocksService.getPositionForOffset,
      )) {
        return;
      }

      if (state.editorConfig.config.enableInteractiveSelection) {
        _textSelectionService.onSelectionCompleted(state);
      }
    }

    if (_shouldShowSelectionToolbar) {
      _selectionActionsService.showToolbar(state);
    }
  }

  // By default, it selects a word through RenderEditable.selectWord if  selectionEnabled and shows buttons if necessary.
  void onDoubleTapDown(TapDownDetails details, EditorState state) {
    if (state.editorConfig.config.enableInteractiveSelection) {
      _textSelectionService.selectWordsInRange(
        state.lastTapDown.position!,
        null,
        SelectionChangedCause.tap,
        state,
      );

      // Allow the selection to get updated before trying to bring up toolbars.
      // If double tap happens on an editor that doesn't have focus,
      // selection hasn't been set when the toolbars get added.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_shouldShowSelectionToolbar) {
          _selectionActionsService.showToolbar(state);
        }
      });
    }
  }

  // By default, it selects a text position specified in details.
  void onDragSelectionStart(DragStartDetails details, EditorState state) {
    final newSelection = _textSelectionService.selectPositionAt(
      from: details.globalPosition,
      cause: SelectionChangedCause.drag,
      state: state,
    );

    // Fail safe
    if (newSelection == null) {
      return;
    }

    // Make sure to remember the origin for extend selection.
    state.extendSelection.setOrigin(newSelection);
  }

  // By default, it updates the selection location specified in the provided details objects.
  void onDragSelectionUpdate(
    DragStartDetails startDetails,
    DragUpdateDetails updateDetails,
    EditorState state,
  ) {
    _textSelectionService.extendSelection(
      updateDetails.globalPosition,
      state,
      cause: SelectionChangedCause.drag,
    );
  }

  // === PRIVATE ===

  bool _isPositionSelected(TapUpDetails details, EditorState state) {
    if (state.document.document.isEmpty()) {
      return false;
    }

    final pos = _linesBlocksService.getPositionForOffset(
      details.globalPosition,
      state,
    );
    final result = state.document.document.querySegmentLeafNode(pos.offset);
    final line = result.line;

    if (line == null) {
      return false;
    }

    final segmentLeaf = result.leaf;

    if (segmentLeaf == null && line.length == 1) {
      updateSelection(
        TextSelection.collapsed(offset: pos.offset),
        ChangeSource.LOCAL,
        state,
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
