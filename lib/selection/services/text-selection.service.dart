import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../blocks/services/lines-blocks.service.dart';
import '../../controller/services/editor-text.service.dart';
import '../../controller/state/editor-controller.state.dart';
import '../../cursor/services/cursor.service.dart';
import '../../documents/models/change-source.enum.dart';
import '../../editor/state/editor-state-widget.state.dart';
import '../../editor/state/extend-selection.state.dart';
import '../../editor/state/focus-node.state.dart';
import '../../inputs/services/clipboard.service.dart';
import '../../inputs/services/keyboard.service.dart';
import '../../inputs/state/keyboard-visible.state.dart';
import '../state/last-tap-down.state.dart';
import 'selection-actions.service.dart';
import 'text-selection.utils.dart';

class TextSelectionService {
  final _editorStateWidgetState = EditorStateWidgetState();
  final _editorTextService = EditorTextService();
  final _editorControllerState = EditorControllerState();
  final _extendSelectionState = ExtendSelectionState();
  final _cursorService = CursorService();
  final _clipboardService = ClipboardService();
  final _linesBlocksService = LinesBlocksService();
  final _textSelectionUtils = TextSelectionUtils();
  final _lastTapDownState = LastTapDownState();
  final _selectionActionsService = SelectionActionsService();
  final _keyboardService = KeyboardService();
  final _keyboardVisibleState = KeyboardVisibleState();
  final _focusNodeState = FocusNodeState();

  factory TextSelectionService() => _instance;

  static final _instance = TextSelectionService._privateConstructor();

  TextSelectionService._privateConstructor();

  bool selectAllEnabled() => _clipboardService.toolbarOptions().selectAll;

  // Selects the set words of a paragraph in a given range of global positions.
  // The first and last endpoints of the selection will always be at the beginning and end of a word respectively.
  void selectWordsInRange(
    Offset from,
    Offset? to,
    SelectionChangedCause cause,
  ) {
    final firstPosition = _linesBlocksService.getPositionForOffset(from);
    final firstWord = _textSelectionUtils.getWordAtPosition(firstPosition);
    final lastWord = to == null
        ? firstWord
        : _textSelectionUtils.getWordAtPosition(
            _linesBlocksService.getPositionForOffset(to),
          );

    handleSelectionChange(
      TextSelection(
        baseOffset: firstWord.base.offset,
        extentOffset: lastWord.extent.offset,
        affinity: firstWord.affinity,
      ),
      cause,
    );
  }

  // Move the selection to the beginning or end of a word.
  void selectWordEdge(SelectionChangedCause cause) {
    assert(_lastTapDownState.position != null);

    final position = _linesBlocksService.getPositionForOffset(
      _lastTapDownState.position!,
    );
    final child = _linesBlocksService.childAtPosition(position);
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
      handleSelectionChange(
        TextSelection.collapsed(offset: word.start),
        cause,
      );
    } else {
      handleSelectionChange(
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
    Offset? to,
  }) {
    final fromPosition = _linesBlocksService.getPositionForOffset(from);
    final toPosition =
        to == null ? null : _linesBlocksService.getPositionForOffset(to);
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

    // Call onSelectionChanged only when the selection actually changed.
    handleSelectionChange(newSelection, cause);

    return newSelection;
  }

  void selectAll(SelectionChangedCause cause) {
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
      );
    }
  }

  // Extends current selection to the position closest to specified offset.
  void extendSelection(
    Offset to, {
    required SelectionChangedCause cause,
  }) {
    final selOrigin = _extendSelectionState.origin;

    // The below logic does not exactly match the native version because
    // we do not allow swapping of base and extent positions.
    assert(selOrigin != null);

    final selection = _editorControllerState.controller.selection;
    final toPosition = _linesBlocksService.getPositionForOffset(to);

    if (toPosition.offset < selOrigin!.baseOffset) {
      handleSelectionChange(
        TextSelection(
          baseOffset: toPosition.offset,
          extentOffset: selOrigin.extentOffset,
          affinity: selection.affinity,
        ),
        cause,
      );
    } else if (toPosition.offset > selOrigin.extentOffset) {
      handleSelectionChange(
        TextSelection(
          baseOffset: selOrigin.baseOffset,
          extentOffset: toPosition.offset,
          affinity: selection.affinity,
        ),
        cause,
      );
    }
  }

  void handleSelectionChange(
    TextSelection nextSelection,
    SelectionChangedCause cause,
  ) {
    final focusingEmpty = nextSelection.baseOffset == 0 &&
        nextSelection.extentOffset == 0 &&
        !_focusNodeState.node.hasFocus;

    if (nextSelection == _editorControllerState.controller.selection &&
        cause != SelectionChangedCause.keyboard &&
        !focusingEmpty) {
      return;
    }

    onSelectionChanged(nextSelection, cause);
  }

  // Ticks only when a new selection is made.
  // Triggers the rendering of the selection handles.
  void onSelectionChanged(
    TextSelection selection,
    SelectionChangedCause cause,
  ) {
    final oldSelection = _editorControllerState.controller.selection;

    _editorControllerState.controller.updateSelection(
      selection,
      ChangeSource.LOCAL,
    );

    // Mobiles only
    _editorStateWidgetState.editor.selectionActionsController?.handlesVisible =
        _selectionActionsService.shouldShowSelectionHandles();

    if (!_keyboardVisibleState.isVisible) {
      // This will show the keyboard for all selection changes on the editor,
      // not just changes triggered by user gestures.
      _keyboardService.requestKeyboard();
    }

    if (cause == SelectionChangedCause.drag) {
      // When user updates the selection while dragging make sure to bring
      // the updated position (base or extent) into view.
      if (oldSelection.baseOffset != selection.baseOffset) {
        _cursorService.bringIntoView(selection.base);
      } else if (oldSelection.extentOffset != selection.extentOffset) {
        _cursorService.bringIntoView(selection.extent);
      }
    }
  }

  void onSelectionCompleted() {
    _editorControllerState.controller.onSelectionCompleted?.call();
  }
}
