import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../blocks/services/lines-blocks.service.dart';
import '../../documents/models/nodes/node.model.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/widgets/multiline-text-area-renderer.dart';

class TextSelectionUtils {
  final _linesBlocksService = LinesBlocksService();

  factory TextSelectionUtils() => _instance;

  static final _instance = TextSelectionUtils._privateConstructor();

  TextSelectionUtils._privateConstructor();

  // When multiple lines of text are selected at once we need to compute the
  // textSelection for each one of them.
  // The local selection is computed as the union between the extent of the text
  // selection and the extend of the line of text.
  TextSelection getLocalSelection(
    NodeM node,
    TextSelection selection,
    fromParent,
  ) {
    final base = fromParent ? node.offset : node.documentOffset;

    assert(base <= selection.end && selection.start <= base + node.length - 1);

    final offset = fromParent ? node.offset : node.documentOffset;

    return selection.copyWith(
      baseOffset: math.max(selection.start - offset, 0),
      extentOffset: math.min(selection.end - offset, node.length - 1),
    );
  }

  TextSelection getWordAtPosition(
    TextPosition position,
    EditorState state,
  ) {
    final word = state.refs.renderer.getWordBoundary(position);

    // When long-pressing past the end of the text, we want a collapsed cursor.
    if (position.offset >= word.end) {
      return TextSelection.fromPosition(position);
    }

    return TextSelection(
      baseOffset: word.start,
      extentOffset: word.end,
    );
  }

  TextSelection getLineAtPosition(
    TextPosition position,
    MultilineTextAreaRenderer renderer,
    EditorState state,
  ) {
    final line = getLineAtOffset(position, renderer, state);

    // When long-pressing past the end of the text, we want a collapsed cursor.
    if (position.offset >= line.end) {
      return TextSelection.fromPosition(position);
    }

    return TextSelection(
      baseOffset: line.start,
      extentOffset: line.end,
    );
  }

  TextSelection getLineAtOffset(
    TextPosition position,
    MultilineTextAreaRenderer renderer,
    EditorState state,
  ) {
    final child = _linesBlocksService.childAtPosition(position, state);
    final nodeOffset = child.container.offset;
    final localPosition = TextPosition(
      offset: position.offset - nodeOffset,
      affinity: position.affinity,
    );
    final localLineRange = child.getLineBoundary(localPosition);
    final line = TextRange(
      start: localLineRange.start + nodeOffset,
      end: localLineRange.end + nodeOffset,
    );

    return TextSelection(
      baseOffset: line.start,
      extentOffset: line.end,
    );
  }

  TextRange getWordBoundary(
    TextPosition position,
    MultilineTextAreaRenderer renderer,
    EditorState state,
  ) {
    final child = _linesBlocksService.childAtPosition(position, state);
    final nodeOffset = child.container.offset;
    final localPosition = TextPosition(
      offset: position.offset - nodeOffset,
      affinity: position.affinity,
    );
    final localWord = child.getWordBoundary(localPosition);

    return TextRange(
      start: localWord.start + nodeOffset,
      end: localWord.end + nodeOffset,
    );
  }

  // Returns the TextPosition above the given offset into the text.
  // If the offset is already on the first line, the offset of the first character will be returned.
  TextPosition getTextPositionAbove(
    TextPosition position,
    MultilineTextAreaRenderer renderer,
    EditorState state,
  ) {
    final child = _linesBlocksService.childAtPosition(position, state);
    final localPosition = TextPosition(
      offset: position.offset - child.container.documentOffset,
    );
    var newPosition = child.getPositionAbove(localPosition);

    if (newPosition == null) {
      // There was no text above in the current child, check the direct sibling.
      final sibling = renderer.childBefore(child);

      if (sibling == null) {
        // Reached beginning of the document, move to the first character
        newPosition = const TextPosition(offset: 0);
      } else {
        final caretOffset = child.getOffsetForCaret(localPosition);
        final testPosition = TextPosition(offset: sibling.container.length - 1);
        final testOffset = sibling.getOffsetForCaret(testPosition);
        final finalOffset = Offset(caretOffset.dx, testOffset.dy);
        final siblingPosition = sibling.getPositionForOffset(finalOffset);
        newPosition = TextPosition(
          offset: sibling.container.documentOffset + siblingPosition.offset,
        );
      }
    } else {
      newPosition = TextPosition(
        offset: child.container.documentOffset + newPosition.offset,
      );
    }

    return newPosition;
  }

  // Returns the TextPosition below the given offset into the text.
  // If the offset is already on the last line, the offset of the last character will be returned.
  TextPosition getTextPositionBelow(
    TextPosition position,
    MultilineTextAreaRenderer renderer,
    EditorState state,
  ) {
    final child = _linesBlocksService.childAtPosition(position, state);
    final localPosition = TextPosition(
      offset: position.offset - child.container.documentOffset,
    );
    var newPosition = child.getPositionBelow(localPosition);

    if (newPosition == null) {
      // There was no text above in the current child, check the direct sibling.
      final sibling = renderer.childAfter(child);

      if (sibling == null) {
        // Reached beginning of the document, move to the last character
        newPosition = TextPosition(offset: state.document.document.length - 1);
      } else {
        final caretOffset = child.getOffsetForCaret(localPosition);
        const testPosition = TextPosition(offset: 0);
        final testOffset = sibling.getOffsetForCaret(testPosition);
        final finalOffset = Offset(caretOffset.dx, testOffset.dy);
        final siblingPosition = sibling.getPositionForOffset(finalOffset);
        newPosition = TextPosition(
          offset: sibling.container.documentOffset + siblingPosition.offset,
        );
      }
    } else {
      newPosition = TextPosition(
        offset: child.container.documentOffset + newPosition.offset,
      );
    }

    return newPosition;
  }
}
