import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../blocks/services/lines-blocks.service.dart';
import '../../controller/state/document.state.dart';
import '../../controller/state/editor-controller.state.dart';
import '../../documents/models/change-source.enum.dart';
import '../../editor/state/editor-config.state.dart';
import '../../editor/state/extend-selection.state.dart';
import '../../inputs/services/clipboard.service.dart';
import '../../inputs/services/keyboard.service.dart';
import '../../shared/utils/platform.utils.dart';
import '../state/last-tap-down.state.dart';
import 'selection-actions.service.dart';
import 'text-selection.service.dart';

class TextGesturesService {
  final _editorControllerState = EditorControllerState();
  final _textSelectionService = TextSelectionService();
  final _extendSelectionState = ExtendSelectionState();
  final _selectionActionsService = SelectionActionsService();
  final _keyboardService = KeyboardService();
  final _editorConfigState = EditorConfigState();
  final _documentState = DocumentState();
  final _clipboardService = ClipboardService();
  final _linesBlocksService = LinesBlocksService();
  final _lastTapDownState = LastTapDownState();

  // Whether to show the selection buttons.
  // It is based on the signal source when a onTapDown is called.
  // Will return true if current onTapDown event is triggered by a touch or a stylus.
  bool _shouldShowSelectionToolbar = true;

  factory TextGesturesService() => _instance;

  static final _instance = TextGesturesService._privateConstructor();

  TextGesturesService._privateConstructor();

  bool selectAllEnabled() => _clipboardService.toolbarOptions().selectAll;

  void updateSelection(TextSelection textSelection, ChangeSource source) {
    _editorControllerState.controller.updateSelection(textSelection, source);
  }

  // === HANDLERS ===

  // By default, it forwards the tap to RenderEditable.handleTapDown and sets shouldShowSelectionToolbar
  // to true if the tap was initiated by a finger or stylus.
  void onTapDown(TapDownDetails details) {
    if (_editorConfigState.config.onTapDown != null) {
      if (_editorConfigState.config.onTapDown!(
        details,
        _linesBlocksService.getPositionForOffset,
      )) {
        return;
      }
    }

    _lastTapDownState.setLastTapDown(details.globalPosition);

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
  void onForcePressStart(ForcePressDetails details) {
    assert(_editorConfigState.config.forcePressEnabled);

    if (!_editorConfigState.config.forcePressEnabled) {
      return;
    }

    _shouldShowSelectionToolbar = true;
    if (_editorConfigState.config.enableInteractiveSelection) {
      _textSelectionService.selectWordsInRange(
        details.globalPosition,
        null,
        SelectionChangedCause.forcePress,
      );
    }

    if (_editorConfigState.config.enableInteractiveSelection &&
        _shouldShowSelectionToolbar) {
      _selectionActionsService.showToolbar();
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
  ) {
    if (_editorConfigState.config.onTapUp != null &&
        _editorConfigState.config.onTapUp!(
          details,
          _linesBlocksService.getPositionForOffset,
        )) {
      return;
    }

    _selectionActionsService.hideToolbar();

    try {
      if (_editorConfigState.config.enableInteractiveSelection &&
          !_isPositionSelected(details)) {
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
                  cause: SelectionChangedCause.tap,
                );
                _textSelectionService.onSelectionCompleted();
              } else {
                _textSelectionService.selectPositionAt(
                  from: _lastTapDownState.position!,
                  cause: SelectionChangedCause.tap,
                );
                _textSelectionService.onSelectionCompleted();
              }

              break;

            case PointerDeviceKind.touch:

            case PointerDeviceKind.unknown:
              // On macOS/iOS/iPadOS a touch tap places the cursor at the edge of the word.
              _textSelectionService.selectWordEdge(SelectionChangedCause.tap);
              _textSelectionService.onSelectionCompleted();
              break;

            case PointerDeviceKind.trackpad:
              // TODO Handle this case
              break;
          }
        } else {
          _textSelectionService.selectPositionAt(
            from: _lastTapDownState.position!,
            cause: SelectionChangedCause.tap,
          );

          _textSelectionService.onSelectionCompleted();
        }
      }
    } finally {
      _keyboardService.requestKeyboard();
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
  ) {
    if (_editorConfigState.config.onSingleLongTapStart != null) {
      if (_editorConfigState.config.onSingleLongTapStart!(
        details,
        _linesBlocksService.getPositionForOffset,
      )) {
        return;
      }
    }

    if (_editorConfigState.config.enableInteractiveSelection) {
      if (isAppleOS(platform)) {
        _textSelectionService.selectPositionAt(
          from: details.globalPosition,
          cause: SelectionChangedCause.longPress,
        );
      } else {
        _textSelectionService.selectWordsInRange(
          _lastTapDownState.position!,
          null,
          SelectionChangedCause.longPress,
        );
        Feedback.forLongPress(context);
      }
    }
  }

  // By default, it updates the selection location specified in details if selection is enabled.
  void onSingleLongTapMoveUpdate(
    LongPressMoveUpdateDetails details,
    TargetPlatform platform,
  ) {
    if (_editorConfigState.config.onSingleLongTapMoveUpdate != null) {
      if (_editorConfigState.config.onSingleLongTapMoveUpdate!(
        details,
        _linesBlocksService.getPositionForOffset,
      )) {
        return;
      }
    }

    if (!_editorConfigState.config.enableInteractiveSelection) {
      return;
    }

    if (isAppleOS(platform)) {
      _textSelectionService.selectPositionAt(
        from: details.globalPosition,
        cause: SelectionChangedCause.longPress,
      );
    } else {
      _textSelectionService.selectWordsInRange(
        details.globalPosition - details.offsetFromOrigin,
        details.globalPosition,
        SelectionChangedCause.longPress,
      );
    }
  }

  // By default, it shows buttons if necessary.
  void onSingleLongTapEnd(LongPressEndDetails details) {
    if (_editorConfigState.config.onSingleLongTapEnd != null) {
      if (_editorConfigState.config.onSingleLongTapEnd!(
        details,
        _linesBlocksService.getPositionForOffset,
      )) {
        return;
      }

      if (_editorConfigState.config.enableInteractiveSelection) {
        _textSelectionService.onSelectionCompleted();
      }
    }

    if (_shouldShowSelectionToolbar) {
      _selectionActionsService.showToolbar();
    }
  }

  // By default, it selects a word through RenderEditable.selectWord if  selectionEnabled and shows buttons if necessary.
  void onDoubleTapDown(TapDownDetails details) {
    if (_editorConfigState.config.enableInteractiveSelection) {
      _textSelectionService.selectWordsInRange(
        _lastTapDownState.position!,
        null,
        SelectionChangedCause.tap,
      );

      // Allow the selection to get updated before trying to bring up toolbars.
      // If double tap happens on an editor that doesn't have focus,
      // selection hasn't been set when the toolbars get added.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_shouldShowSelectionToolbar) {
          _selectionActionsService.showToolbar();
        }
      });
    }
  }

  // By default, it selects a text position specified in details.
  void onDragSelectionStart(DragStartDetails details) {
    final newSelection = _textSelectionService.selectPositionAt(
      from: details.globalPosition,
      cause: SelectionChangedCause.drag,
    );

    // Fail safe
    if (newSelection == null) {
      return;
    }

    // Make sure to remember the origin for extend selection.
    _extendSelectionState.setOrigin(newSelection);
  }

  // By default, it updates the selection location specified in the provided details objects.
  void onDragSelectionUpdate(
    DragStartDetails startDetails,
    DragUpdateDetails updateDetails,
  ) {
    _textSelectionService.extendSelection(
      updateDetails.globalPosition,
      cause: SelectionChangedCause.drag,
    );
  }

  // === PRIVATE ===

  bool _isPositionSelected(TapUpDetails details) {
    if (_documentState.document.isEmpty()) {
      return false;
    }

    final pos = _linesBlocksService.getPositionForOffset(
      details.globalPosition,
    );
    final result = _documentState.document.querySegmentLeafNode(pos.offset);
    final line = result.item1;

    if (line == null) {
      return false;
    }

    final segmentLeaf = result.item2;

    if (segmentLeaf == null && line.length == 1) {
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
