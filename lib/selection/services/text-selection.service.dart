import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../blocks/services/lines-blocks.service.dart';
import '../../controller/services/editor-text.service.dart';
import '../../cursor/services/cursor.service.dart';
import '../../documents/models/change-source.enum.dart';
import '../../inputs/services/clipboard.service.dart';
import '../../inputs/services/keyboard.service.dart';
import '../../shared/state/editor.state.dart';
import 'selection-actions.service.dart';
import 'text-selection.utils.dart';

class TextSelectionService {
  final _editorTextService = EditorTextService();
  final _cursorService = CursorService();
  final _clipboardService = ClipboardService();
  final _linesBlocksService = LinesBlocksService();
  final _textSelectionUtils = TextSelectionUtils();
  final _selectionActionsService = SelectionActionsService();
  final _keyboardService = KeyboardService();

  factory TextSelectionService() => _instance;

  static final _instance = TextSelectionService._privateConstructor();

  TextSelectionService._privateConstructor();

  bool selectAllEnabled(EditorState state) =>
      _clipboardService.toolbarOptions(state).selectAll;

  // Selects the set words of a paragraph in a given range of global positions.
  // The first and last endpoints of the selection will always be at the beginning and end of a word respectively.
  void selectWordsInRange(
    Offset from,
    Offset? to,
    SelectionChangedCause cause,
    EditorState state,
  ) {
    final firstPosition = _linesBlocksService.getPositionForOffset(from, state);
    final firstWord = _textSelectionUtils.getWordAtPosition(
      firstPosition,
      state,
    );
    final lastWord = to == null
        ? firstWord
        : _textSelectionUtils.getWordAtPosition(
            _linesBlocksService.getPositionForOffset(to, state),
            state,
          );

    handleSelectionChange(
      TextSelection(
        baseOffset: firstWord.base.offset,
        extentOffset: lastWord.extent.offset,
        affinity: firstWord.affinity,
      ),
      cause,
      state,
    );
  }

  // Move the selection to the beginning or end of a word.
  void selectWordEdge(SelectionChangedCause cause, EditorState state) {
    assert(state.lastTapDown.position != null);

    final position = _linesBlocksService.getPositionForOffset(
      state.lastTapDown.position!,
      state,
    );
    final child = _linesBlocksService.childAtPosition(position, state);
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
        state,
      );
    } else {
      handleSelectionChange(
        TextSelection.collapsed(
          offset: word.end,
          affinity: TextAffinity.upstream,
        ),
        cause,
        state,
      );
    }
  }

  // Returns the new selection.
  // Note that the returned value may not be yet reflected in the latest widget state.
  // Returns null if no change occurred.
  TextSelection? selectPositionAt({
    required Offset from,
    required SelectionChangedCause cause,
    required EditorState state,
    Offset? to,
  }) {
    final fromPosition = _linesBlocksService.getPositionForOffset(from, state);
    final toPosition =
        to == null ? null : _linesBlocksService.getPositionForOffset(to, state);
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
    handleSelectionChange(newSelection, cause, state);

    return newSelection;
  }

  void selectAll(SelectionChangedCause cause, EditorState state) {
    _editorTextService.userUpdateTextEditingValue(
      state.refs.editorController.plainTextEditingValue.copyWith(
        selection: TextSelection(
          baseOffset: 0,
          extentOffset:
              state.refs.editorController.plainTextEditingValue.text.length,
        ),
      ),
      cause,
      state,
    );

    if (cause == SelectionChangedCause.toolbar) {
      _cursorService.bringIntoView(
        state.refs.editorController.plainTextEditingValue.selection.extent,
        state,
      );
    }
  }

  // Extends current selection to the position closest to specified offset.
  void extendSelection(
    Offset to,
    EditorState state, {
    required SelectionChangedCause cause,
  }) {
    final selOrigin = state.extendSelection.origin;

    // The below logic does not exactly match the native version because
    // we do not allow swapping of base and extent positions.
    if (selOrigin == null) {
      return;
    }

    final selection = state.refs.editorController.selection;
    final toPosition = _linesBlocksService.getPositionForOffset(to, state);

    if (toPosition.offset < selOrigin.baseOffset) {
      handleSelectionChange(
        TextSelection(
          baseOffset: toPosition.offset,
          extentOffset: selOrigin.extentOffset,
          affinity: selection.affinity,
        ),
        cause,
        state,
      );
    } else if (toPosition.offset > selOrigin.extentOffset) {
      handleSelectionChange(
        TextSelection(
          baseOffset: selOrigin.baseOffset,
          extentOffset: toPosition.offset,
          affinity: selection.affinity,
        ),
        cause,
        state,
      );
    }
  }

  void handleSelectionChange(
    TextSelection nextSelection,
    SelectionChangedCause cause,
    EditorState state,
  ) {
    final focusingEmpty = nextSelection.baseOffset == 0 &&
        nextSelection.extentOffset == 0 &&
        !state.refs.focusNode.hasFocus;

    if (nextSelection == state.refs.editorController.selection &&
        cause != SelectionChangedCause.keyboard &&
        !focusingEmpty) {
      return;
    }

    onSelectionChanged(nextSelection, cause, state);
  }

  // Ticks only when a new selection is made.
  // Triggers the rendering of the selection handles.
  void onSelectionChanged(
    TextSelection selection,
    SelectionChangedCause cause,
    EditorState state,
  ) {
    final oldSelection = state.refs.editorController.selection;

    state.refs.editorController.updateSelection(
      selection,
      ChangeSource.LOCAL,
    );

    // Mobiles only
    state.refs.editorState.selectionActionsController?.handlesVisible =
        _selectionActionsService.shouldShowSelectionHandles(state);

    if (!state.keyboardVisible.isVisible) {
      // This will show the keyboard for all selection changes on the editor,
      // not just changes triggered by user gestures.
      _keyboardService.requestKeyboard(state);
    }

    if (cause == SelectionChangedCause.drag) {
      // When user updates the selection while dragging make sure to bring
      // the updated position (base or extent) into view.
      if (oldSelection.baseOffset != selection.baseOffset) {
        _cursorService.bringIntoView(selection.base, state);
      } else if (oldSelection.extentOffset != selection.extentOffset) {
        _cursorService.bringIntoView(selection.extent, state);
      }
    }
  }

  void onSelectionCompleted(EditorState state) {
    state.refs.editorController.onSelectionCompleted?.call();
  }
}
