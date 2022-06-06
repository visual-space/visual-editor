import 'package:flutter/rendering.dart';

import '../../blocks/models/editable-box-renderer.model.dart';
import '../widgets/editable-container-box-renderer.dart';

class EditorRendererUtils {
  static final _instance = EditorRendererUtils._privateConstructor();

  factory EditorRendererUtils() => _instance;

  EditorRendererUtils._privateConstructor();

  RenderEditableBox childAtPosition(
    TextPosition position,
    EditableContainerBoxRenderer renderer,
  ) {
    assert(renderer.firstChild != null);

    final targetNode = renderer.container
        .queryChild(
          position.offset,
          false,
        )
        .node;
    var targetChild = renderer.firstChild;

    while (targetChild != null) {
      if (targetChild.container == targetNode) {
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
  RenderEditableBox childAtOffset(
    Offset offset,
    EditableContainerBoxRenderer renderer,
  ) {
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
  TextPosition getPositionForOffset(
    Offset offset,
    EditableContainerBoxRenderer renderer,
  ) {
    final local = renderer.globalToLocal(offset);
    final child = childAtOffset(local, renderer);
    final parentData = child.parentData as BoxParentData;
    final localOffset = local - parentData.offset;
    final localPosition = child.getPositionForOffset(localOffset);

    return TextPosition(
      offset: localPosition.offset + child.container.offset,
      affinity: localPosition.affinity,
    );
  }

  double preferredLineHeight(
    TextPosition position,
    EditableContainerBoxRenderer renderer,
  ) {
    final child = childAtPosition(position, renderer);

    return child.preferredLineHeight(
      TextPosition(offset: position.offset - child.container.offset),
    );
  }
}
