import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../controller/state/document.state.dart';
import '../../documents/models/change-source.enum.dart';
import '../../editor/services/clipboard.service.dart';
import '../../editor/services/editor-renderer.utils.dart';
import '../../editor/state/editor-config.state.dart';
import '../../editor/widgets/editor-renderer.dart';
import '../../inputs/services/keyboard.service.dart';
import '../../shared/utils/platform.utils.dart';
import '../state/last-tap-down.state.dart';
import 'selection-actions.service.dart';
import 'text-selection.service.dart';

class TextGesturesUtils {
  final _textSelectionService = TextSelectionService();
  final _selectionActionsService = SelectionActionsService();
  final _keyboardService = KeyboardService();
  final _editorConfigState = EditorConfigState();
  final _documentState = DocumentState();
  final _clipboardService = ClipboardService();
  final _editorRendererUtils = EditorRendererUtils();
  final _lastTapDownState = LastTapDownState();

  // Whether to show the selection buttons.
  // It is based on the signal source when a onTapDown is called.
  // Will return true if current onTapDown event is triggered by a touch or a stylus.
  bool _shouldShowSelectionToolbar = true;

  factory TextGesturesUtils() => _instance;

  static final _instance = TextGesturesUtils._privateConstructor();

  TextGesturesUtils._privateConstructor();

  bool selectAllEnabled() => _clipboardService.toolbarOptions().selectAll;

  // +++ DEL
  late Function(TextSelection textSelection, ChangeSource source)
      _updateSelection;

  // REMOVE +++ Temporary method until we can refactor the sharing of the controller and state
  // Could have been a stream until
  void setUpdateSelection(
    Function(TextSelection textSelection, ChangeSource source) updateSelection,
  ) {
    _updateSelection = updateSelection;
  }

  void updateSelection(TextSelection textSelection, ChangeSource source) {
    _updateSelection(textSelection, source);
  }

  // === HANDLERS ===

  // By default, it forwards the tap to RenderEditable.handleTapDown and sets shouldShowSelectionToolbar
  // to true if the tap was initiated by a finger or stylus.
  void onTapDown(TapDownDetails details, EditorRenderer editorRenderer) {
    if (_editorConfigState.config.onTapDown != null) {
      if (_editorConfigState.config.onTapDown!(
        details,
        (offset) => _editorRendererUtils.getPositionForOffset(
          offset,
          editorRenderer,
        ),
      )) {
        return;
      }
    }

    editorRenderer.handleTapDown(details);

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
    EditorRenderer editorRenderer,
  ) {
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
        editorRenderer,
      );
    }

    if (_editorConfigState.config.enableInteractiveSelection &&
        _shouldShowSelectionToolbar) {
      _selectionActionsService.showToolbar();
    }
  }

  // By default, it selects words in the range specified in details and shows buttons if it is necessary.
  // This callback is only applicable when force press is enabled.
  void onForcePressEnd(
    ForcePressDetails details,
    EditorRenderer editorRenderer,
  ) {
    // +++ REVIEW It appears that this feature was disabled in the original code.
    // No longer working. Maybe it can be restored.
    //
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
    EditorRenderer editorRenderer,
  ) {
    if (_editorConfigState.config.onTapUp != null &&
        _editorConfigState.config.onTapUp!(
          details,
          (offset) => _editorRendererUtils.getPositionForOffset(
            offset,
            editorRenderer,
          ),
        )) {
      return;
    }

    _selectionActionsService.hideToolbar();

    try {
      if (_editorConfigState.config.enableInteractiveSelection &&
          !_isPositionSelected(details, editorRenderer)) {
        if (isAppleOS(platform)) {
          switch (details.kind) {
            case PointerDeviceKind.mouse:

            case PointerDeviceKind.stylus:

            case PointerDeviceKind.invertedStylus:
              // Precise devices should place the cursor at a precise position.
              // If `Shift` key is pressed then extend current selection instead.
              if (_isShiftClick(details.kind)) {
                editorRenderer
                  ..extendSelection(
                    details.globalPosition,
                    cause: SelectionChangedCause.tap,
                  )
                  ..onSelectionCompleted();
              } else {
                _textSelectionService.selectPositionAt(
                  from: _lastTapDownState.position!,
                  cause: SelectionChangedCause.tap,
                  editorRenderer: editorRenderer,
                );
                editorRenderer.onSelectionCompleted();
              }

              break;

            case PointerDeviceKind.touch:

            case PointerDeviceKind.unknown:
              // On macOS/iOS/iPadOS a touch tap places the cursor at the edge of the word.
              _textSelectionService.selectWordEdge(
                  SelectionChangedCause.tap, editorRenderer);
              editorRenderer.onSelectionCompleted();
              break;

            case PointerDeviceKind.trackpad:
              // TODO Handle this case
              break;
          }
        } else {
          _textSelectionService.selectPositionAt(
            from: _lastTapDownState.position!,
            cause: SelectionChangedCause.tap,
            editorRenderer: editorRenderer,
          );

          editorRenderer.onSelectionCompleted();
        }
      }
    } finally {
      _keyboardService.requestKeyboard();
    }
  }

  // By default, it services as place holder to enable subclass override.
  void onSingleTapCancel() {
    // Subclass should override this method if needed.
  }

  // By default, it selects text position specified in details if selection is enabled.
  void onSingleLongTapStart(
    LongPressStartDetails details,
    TargetPlatform platform,
    BuildContext context,
    EditorRenderer editorRenderer,
  ) {
    if (_editorConfigState.config.onSingleLongTapStart != null) {
      if (_editorConfigState.config.onSingleLongTapStart!(
        details,
        (offset) => _editorRendererUtils.getPositionForOffset(
          offset,
          editorRenderer,
        ),
      )) {
        return;
      }
    }

    if (_editorConfigState.config.enableInteractiveSelection) {
      if (isAppleOS(platform)) {
        _textSelectionService.selectPositionAt(
          from: details.globalPosition,
          cause: SelectionChangedCause.longPress,
          editorRenderer: editorRenderer,
        );
      } else {
        _textSelectionService.selectWordsInRange(
          _lastTapDownState.position!,
          null,
          SelectionChangedCause.longPress,
          editorRenderer,
        );
        Feedback.forLongPress(context);
      }
    }
  }

  // By default, it updates the selection location specified in details if selection is enabled.
  void onSingleLongTapMoveUpdate(
    LongPressMoveUpdateDetails details,
    TargetPlatform platform,
    EditorRenderer editorRenderer,
  ) {
    if (_editorConfigState.config.onSingleLongTapMoveUpdate != null) {
      if (_editorConfigState.config.onSingleLongTapMoveUpdate!(
        details,
        (offset) => _editorRendererUtils.getPositionForOffset(
          offset,
          editorRenderer,
        ),
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
        editorRenderer: editorRenderer,
      );
    } else {
      _textSelectionService.selectWordsInRange(
        details.globalPosition - details.offsetFromOrigin,
        details.globalPosition,
        SelectionChangedCause.longPress,
        editorRenderer,
      );
    }
  }

  // By default, it shows buttons if necessary.
  void onSingleLongTapEnd(
    LongPressEndDetails details,
    EditorRenderer editorRenderer,
  ) {
    if (_editorConfigState.config.onSingleLongTapEnd != null) {
      if (_editorConfigState.config.onSingleLongTapEnd!(
        details,
        (offset) => _editorRendererUtils.getPositionForOffset(
          offset,
          editorRenderer,
        ),
      )) {
        return;
      }

      if (_editorConfigState.config.enableInteractiveSelection) {
        editorRenderer.onSelectionCompleted();
      }
    }

    if (_shouldShowSelectionToolbar) {
      _selectionActionsService.showToolbar();
    }
  }

  // By default, it selects a word through RenderEditable.selectWord if  selectionEnabled and shows buttons if necessary.
  void onDoubleTapDown(
    TapDownDetails details,
    EditorRenderer editorRenderer,
  ) {
    if (_editorConfigState.config.enableInteractiveSelection) {
      _textSelectionService.selectWordsInRange(
        _lastTapDownState.position!,
        null,
        SelectionChangedCause.tap,
        editorRenderer,
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
  void onDragSelectionStart(
    DragStartDetails details,
    EditorRenderer editorRenderer,
  ) {
    editorRenderer.handleDragStart(details);
  }

  // By default, it updates the selection location specified in the provided details objects.
  void onDragSelectionUpdate(
    DragStartDetails startDetails,
    DragUpdateDetails updateDetails,
    EditorRenderer editorRenderer,
  ) {
    editorRenderer.extendSelection(
      updateDetails.globalPosition,
      cause: SelectionChangedCause.drag,
    );
  }

  // By default, it services as place holder to enable subclass override.
  void onDragSelectionEnd(
    DragEndDetails details,
    EditorRenderer editorRenderer,
  ) {
    editorRenderer.handleDragEnd(details);
  }

  // === PRIVATE ===

  bool _isPositionSelected(
      TapUpDetails details, EditorRenderer editorRenderer) {
    if (_documentState.document.isEmpty()) {
      return false;
    }

    final pos = _editorRendererUtils.getPositionForOffset(
      details.globalPosition,
      editorRenderer,
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
