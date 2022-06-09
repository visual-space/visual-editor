import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../controller/services/editor-text.service.dart';
import '../../controller/state/document.state.dart';
import '../../cursor/services/cursor.service.dart';
import '../../documents/models/change-source.enum.dart';
import '../../editor/services/clipboard.service.dart';
import '../../editor/services/editor-renderer.utils.dart';
import '../../editor/state/editor-config.state.dart';
import '../../editor/widgets/editor-renderer.dart';
import '../../inputs/services/keyboard.service.dart';
import '../../shared/utils/platform.utils.dart';
import 'selection-actions.service.dart';
import 'text-selection.utils.dart';

// +++ Separate TextGesturesService
class TextSelectionService {
  // +++ REMOVE STATIC
  static final _selectionActionsService = SelectionActionsService();
  static final _editorTextService = EditorTextService();
  static final _cursorService = CursorService();
  static final _keyboardService = KeyboardService();
  static final _editorConfigState = EditorConfigState();
  static final _documentState = DocumentState();
  final _clipboardService = ClipboardService();
  final _editorRendererUtils = EditorRendererUtils();
  final _textSelectionUtils = TextSelectionUtils();

  // +++ STATE
  Offset? lastTapDownPosition;

  // +++ DEL
  // The delegate for this TextSelectionGesturesBuilder.
  // The delegate provides the builder with information about what actions can currently be performed on the textfield.
  // Based on this, the builder adds the correct gesture handlers to the gesture detector.
  // final TextSelectionGesturesBuilderDelegate delegate;
  // late VisualEditorState state;

  // Whether to show the selection buttons.
  // It is based on the signal source when a onTapDown is called.
  // Will return true if current onTapDown event is triggered by a touch or a stylus.
  bool _shouldShowSelectionToolbar = true;

  factory TextSelectionService() => _instance;

  static final _instance = TextSelectionService._privateConstructor();

  TextSelectionService._privateConstructor();

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
      selectWordsInRange(
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
                selectPositionAt(
                  from: lastTapDownPosition!,
                  cause: SelectionChangedCause.tap,
                  editorRenderer: editorRenderer,
                );
                editorRenderer.onSelectionCompleted();
              }

              break;

            case PointerDeviceKind.touch:

            case PointerDeviceKind.unknown:
              // On macOS/iOS/iPadOS a touch tap places the cursor at the edge of the word.
              selectWordEdge(SelectionChangedCause.tap, editorRenderer);
              editorRenderer.onSelectionCompleted();
              break;

            case PointerDeviceKind.trackpad:
              // TODO Handle this case
              break;
          }
        } else {
          selectPositionAt(
            from: lastTapDownPosition!,
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
        selectPositionAt(
          from: details.globalPosition,
          cause: SelectionChangedCause.longPress,
          editorRenderer: editorRenderer,
        );
      } else {
        selectWordsInRange(
          lastTapDownPosition!,
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
      selectPositionAt(
        from: details.globalPosition,
        cause: SelectionChangedCause.longPress,
        editorRenderer: editorRenderer,
      );
    } else {
      selectWordsInRange(
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
      selectWordsInRange(
        lastTapDownPosition!,
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

  // === UTILS ===

  // Selects the set words of a paragraph in a given range of global positions.
  // The first and last endpoints of the selection will always be at the beginning and end of a word respectively.
  void selectWordsInRange(
    Offset from,
    Offset? to,
    SelectionChangedCause cause,
    EditorRenderer editorRenderer,
  ) {
    final firstPosition =
        _editorRendererUtils.getPositionForOffset(from, editorRenderer);
    final firstWord = _textSelectionUtils.getWordAtPosition(
      firstPosition,
      editorRenderer,
    );
    final lastWord = to == null
        ? firstWord
        : _textSelectionUtils.getWordAtPosition(
            _editorRendererUtils.getPositionForOffset(to, editorRenderer),
            editorRenderer,
          );

    editorRenderer.handleSelectionChange(
      TextSelection(
        baseOffset: firstWord.base.offset,
        extentOffset: lastWord.extent.offset,
        affinity: firstWord.affinity,
      ),
      cause,
    );
  }

  // Move the selection to the beginning or end of a word.
  void selectWordEdge(
    SelectionChangedCause cause,
    EditorRenderer editorRenderer,
  ) {
    assert(lastTapDownPosition != null);

    final position = _editorRendererUtils.getPositionForOffset(
      lastTapDownPosition!,
      editorRenderer,
    );
    final child =
        _editorRendererUtils.childAtPosition(position, editorRenderer);
    final nodeOffset = child.container.offset;
    final localPosition = TextPosition(
      offset: position.offset - nodeOffset,
      affinity: position.affinity,
    );
    final localWord = child.getWordBoundary(localPosition);
    final word = TextRange(
      start: localWord.start + nodeOffset,
      end: localWord.end + nodeOffset,
    );

    if (position.offset - word.start <= 1) {
      editorRenderer.handleSelectionChange(
        TextSelection.collapsed(offset: word.start),
        cause,
      );
    } else {
      editorRenderer.handleSelectionChange(
        TextSelection.collapsed(
          offset: word.end,
          affinity: TextAffinity.upstream,
        ),
        cause,
      );
    }
  }

  // Returns the new selection.
  // Note that the returned value may not be yet reflected in the latest widget state.
  // Returns null if no change occurred.
  TextSelection? selectPositionAt({
    required Offset from,
    required SelectionChangedCause cause,
    required EditorRenderer editorRenderer,
    Offset? to,
  }) {
    final fromPosition =
        _editorRendererUtils.getPositionForOffset(from, editorRenderer);
    final toPosition = to == null
        ? null
        : _editorRendererUtils.getPositionForOffset(to, editorRenderer);
    var baseOffset = fromPosition.offset;
    var extentOffset = fromPosition.offset;

    if (toPosition != null) {
      baseOffset = math.min(fromPosition.offset, toPosition.offset);
      extentOffset = math.max(fromPosition.offset, toPosition.offset);
    }

    final newSelection = TextSelection(
      baseOffset: baseOffset,
      extentOffset: extentOffset,
      affinity: fromPosition.affinity,
    );

    // Call [onSelectionChanged] only when the selection actually changed.
    editorRenderer.handleSelectionChange(newSelection, cause);

    return newSelection;
  }

  void selectAll(SelectionChangedCause cause, EditorRenderer editorRenderer) {
    _editorTextService.userUpdateTextEditingValue(
      _editorTextService.textEditingValue.copyWith(
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: _editorTextService.textEditingValue.text.length,
        ),
      ),
      cause,
    );

    if (cause == SelectionChangedCause.toolbar) {
      _cursorService.bringIntoView(
        _editorTextService.textEditingValue.selection.extent,
        editorRenderer,
      );
    }
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
