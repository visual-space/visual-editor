import 'package:flutter/rendering.dart';

import '../../document/services/nodes/container.utils.dart';
import '../../document/services/nodes/node.utils.dart';
import '../../shared/models/editable-box-renderer.model.dart';
import '../../shared/state/editor.state.dart';
import '../widgets/editable-text-block-box-renderer.dart';

// Queries for children position at certain coordinates in the document.
class CoordinatesService {
  final _contUtils = ContainerUtils();
  final _nodeUtils = NodeUtils();

  final EditorState state;

  CoordinatesService(this.state);

  // If an EditableTextBlockBoxRenderer is provided it uses it, otherwise it defaults to the EditorRenderer
  EditableBoxRenderer childAtPosition(
    TextPosition position, [
    EditableTextBlockBoxRenderer? blockRenderer,
  ]) {
    final renderer = blockRenderer ?? state.refs.renderer;

    assert(renderer.firstChild != null);

    final offset = position.offset;
    final target = _contUtils.queryChild(renderer.container, offset, false);
    var targetChild = renderer.firstChild;

    while (targetChild != null) {
      if (targetChild.container == target.node) {
        break;
      }

      final newChild = renderer.childAfter(targetChild);

      if (newChild == null) {
        break;
      }

      targetChild = newChild;
    }

    if (targetChild == null) {
      throw 'targetChild should not be null';
    }

    return targetChild;
  }

  // Returns child of this container located at the specified local `offset`.
  // If `offset` is above this container (offset.dy is negative) returns the first child.
  // Likewise, if `offset` is below this container then returns the last child.
  // If an EditableTextBlockBoxRenderer is provided it uses it, otherwise it defaults to the EditorRenderer
  EditableBoxRenderer childAtOffset(
    Offset offset, [
    EditableTextBlockBoxRenderer? blockRenderer,
  ]) {
    final renderer = blockRenderer ?? state.refs.renderer;
    assert(renderer.firstChild != null);

    renderer.resolvePadding();

    if (offset.dy <= renderer.resolvedPadding!.top) {
      return renderer.firstChild!;
    }

    if (offset.dy >= renderer.size.height - renderer.resolvedPadding!.bottom) {
      return renderer.lastChild!;
    }

    var child = renderer.firstChild;
    final dx = -offset.dx;
    var dy = renderer.resolvedPadding!.top;

    while (child != null) {
      if (child.size.contains(offset.translate(dx, -dy))) {
        return child;
      }

      dy += child.size.height;
      child = renderer.childAfter(child);
    }

    throw StateError('No child at offset $offset.');
  }

  // Returns the local coordinates of the endpoints of the given selection.
  // If the selection is collapsed (and therefore occupies a single point), the returned list is of length one.
  // Otherwise, the selection is not collapsed and the returned list is of length two.
  // In this case, however, the two points might actually be co-located (e.g., because of a bidirectional
  // selection that contains some text but whose ends meet in the middle).
  TextPosition getPositionForOffset(Offset offset) {
    final local = state.refs.renderer.globalToLocal(offset);
    final child = childAtOffset(local);
    final parentData = child.parentData as BoxParentData;
    final localOffset = local - parentData.offset;
    final localPosition = child.getPositionForOffset(localOffset);

    // Store the letter position. Works properly if the line is not empty (doesn't contain '\n').
    // For that we got below a condition which solves the problem.
    final letterOffset = localPosition.offset + _nodeUtils.getOffset(child.container);

    final isNotFirstCharInsideDocument = letterOffset > 1;

    // (!) In order to make the caret be placeable before the first letter in the document.
    if (isNotFirstCharInsideDocument) {
      // Selection is also when user taps at a specific place in the editor in order to place the caret.
      final firstLetterOfSelection =
      state.refs.documentController.getPlainTextAtRange(letterOffset - 1, 1);

      // Empty Line
      if (firstLetterOfSelection == '\n') {
        // Move caret at the position of that empty line.
        return TextPosition(
          offset: _nodeUtils.getOffset(child.container),
          affinity: localPosition.affinity,
        );
      }
    }

    return TextPosition(
      offset: letterOffset,
      affinity: localPosition.affinity,
    );
  }

  double preferredLineHeight(TextPosition position) {
    final child = childAtPosition(position);

    return child.preferredLineHeight(
      TextPosition(
        offset: position.offset - _nodeUtils.getOffset(child.container),
      ),
    );
  }
}
