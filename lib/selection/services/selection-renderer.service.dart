import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../doc-tree/services/coordinates.service.dart';
import '../../document/models/nodes/node.model.dart';
import '../../document/services/nodes/node.utils.dart';
import '../../shared/models/editable-box-renderer.model.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/widgets/multiline-text-area-renderer.dart';

// Handles the calculations of positions of various selections.
// It uses the renderers of the lines of text.
class SelectionRendererService {
  late final CoordinatesService _coordinatesService;
  final _nodeUtils = NodeUtils();

  final EditorState state;

  SelectionRendererService(this.state) {
    _coordinatesService = CoordinatesService(state);
  }

  // When multiple lines of text are selected at once we need to compute the
  // textSelection for each one of them.
  // The local selection is computed as the union between the extent of the text
  // selection and the extend of the line of text.
  TextSelection getLocalSelection(
    NodeM node,
    TextSelection selection,
    fromParent,
  ) {
    final base = fromParent
        ? _nodeUtils.getOffset(node)
        : _nodeUtils.getDocumentOffset(node);

    assert(
        base <= selection.end && selection.start <= base + node.charsNum - 1);

    final offset = fromParent
        ? _nodeUtils.getOffset(node)
        : _nodeUtils.getDocumentOffset(node);

    return selection.copyWith(
      baseOffset: math.max(selection.start - offset, 0),
      extentOffset: math.min(selection.end - offset, node.charsNum - 1),
    );
  }

  TextSelection getWordAtPosition(TextPosition position) {
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
  ) {
    final line = getLineAtOffset(position, renderer);

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
  ) {
    final child = _coordinatesService.childAtPosition(position);
    final nodeOffset = _nodeUtils.getOffset(child.container);
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
  ) {
    final child = _coordinatesService.childAtPosition(position);
    final nodeOffset = _nodeUtils.getOffset(child.container);
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
  ) {
    final child = _coordinatesService.childAtPosition(position);
    final localPosition = TextPosition(
      offset: position.offset - _getDocOffset(child),
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
        final charsNum = sibling.container.charsNum;
        final testPosition = TextPosition(offset: charsNum - 1);
        final testOffset = sibling.getOffsetForCaret(testPosition);
        final finalOffset = Offset(caretOffset.dx, testOffset.dy);
        final siblingPosition = sibling.getPositionForOffset(finalOffset);
        newPosition = TextPosition(
          offset: _nodeUtils.getDocumentOffset(sibling.container) +
              siblingPosition.offset,
        );
      }
    } else {
      newPosition = TextPosition(
        offset: _getDocOffset(child) + newPosition.offset,
      );
    }

    return newPosition;
  }

  // Returns the TextPosition below the given offset into the text.
  // If the offset is already on the last line, the offset of the last character will be returned.
  TextPosition getTextPositionBelow(
    TextPosition position,
    MultilineTextAreaRenderer renderer,
  ) {
    final child = _coordinatesService.childAtPosition(position);
    final localPosition = TextPosition(
      offset: position.offset - _getDocOffset(child),
    );
    var newPosition = child.getPositionBelow(localPosition);

    if (newPosition == null) {
      // There was no text above in the current child, check the direct sibling.
      final sibling = renderer.childAfter(child);

      if (sibling == null) {
        // Reached beginning of the document, move to the last character
        newPosition =
            TextPosition(offset: state.refs.documentController.docCharsNum - 1);
      } else {
        final caretOffset = child.getOffsetForCaret(localPosition);
        const testPosition = TextPosition(offset: 0);
        final testOffset = sibling.getOffsetForCaret(testPosition);
        final finalOffset = Offset(caretOffset.dx, testOffset.dy);
        final siblingPosition = sibling.getPositionForOffset(finalOffset);
        newPosition = TextPosition(
          offset: _nodeUtils.getDocumentOffset(sibling.container) +
              siblingPosition.offset,
        );
      }
    } else {
      newPosition = TextPosition(
        offset: _getDocOffset(child) + newPosition.offset,
      );
    }

    return newPosition;
  }

  // === PRIVATE ===

  int _getDocOffset(EditableBoxRenderer child) =>
      _nodeUtils.getDocumentOffset(child.container);
}
