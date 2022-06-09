import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controller/services/editor-text.service.dart';
import '../../cursor/services/cursor.service.dart';
import '../../documents/models/change-source.enum.dart';
import '../../editor/services/clipboard.service.dart';
import '../../editor/services/editor-renderer.utils.dart';
import '../../editor/widgets/editor-renderer.dart';
import '../state/last-tap-down.state.dart';
import 'text-selection.utils.dart';

class TextSelectionService {
  final _editorTextService = EditorTextService();
  final _cursorService = CursorService();
  final _clipboardService = ClipboardService();
  final _editorRendererUtils = EditorRendererUtils();
  final _textSelectionUtils = TextSelectionUtils();
  final _lastTapDownState = LastTapDownState();

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
    assert(_lastTapDownState.position != null);

    final position = _editorRendererUtils.getPositionForOffset(
      _lastTapDownState.position!,
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
}
