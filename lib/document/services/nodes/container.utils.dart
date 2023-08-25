import '../../models/nodes/container.model.dart';
import '../../models/nodes/node-position.model.dart';
import '../../models/nodes/node.model.dart';
import '../../models/nodes/style.model.dart';
import 'node.utils.dart';

final _nodeUtils = NodeUtils();

class ContainerUtils {
  void insert(
    ContainerM container,
    int index,
    Object data,
    StyleM? style, [
    bool overrideRootNode = false,
  ]) {
    assert(index == 0 || (index > 0 && index < container.charsNum));

    if (container.isNotEmpty) {
      final child = queryChild(container, index, false);
      _nodeUtils.insert(child.node!, child.offset, data, style);

      return;
    }

    // Empty
    assert(index == 0);

    final node = container.defaultChild;
    add(container, node);
    _nodeUtils.insert(node, index, data, style);
  }

  void retain(
    ContainerM container,
    int index,
    int? length,
    StyleM? attributes,
  ) {
    assert(container.isNotEmpty);

    final child = queryChild(container, index, false);

    _nodeUtils.retain(child.node, child.offset, length, attributes);
  }

  void delete(
    ContainerM container,
    int index,
    int? length,
  ) {
    assert(container.isNotEmpty);

    final child = queryChild(container, index, false);

    _nodeUtils.delete(child.node, child.offset, length);
  }

  // Adds node to the end of this container children list.
  void add<T extends NodeM?>(ContainerM container, T node) {
    assert(node?.parent == null);

    node?.parent = container;
    container.children.add(node as NodeM);
  }

  // Adds node to the beginning of this container children list.
  void addFirst<T extends NodeM?>(ContainerM container, T node) {
    assert(node?.parent == null);

    node?.parent = container;
    container.children.addFirst(node as NodeM);
  }

  // Removes node from this container.
  void remove<T extends NodeM?>(ContainerM container, T node) {
    assert(node?.parent == container);

    node?.parent = null;
    container.children.remove(node as NodeM);
  }

  // Moves children of this node to newParent.
  void moveChildToNewParent<T extends NodeM?>(
    ContainerM container,
    ContainerM? newParent,
  ) {
    if (container.isEmpty) {
      return;
    }

    final last = newParent!.isEmpty ? null : newParent.last as T?;

    while (container.isNotEmpty) {
      final child = container.first as T;
      child?.unlink();
      add<T>(newParent, child);
    }

    // In case newParent already had children we need to make sure combined list is optimized.
    if (last != null) {
      _nodeUtils.mergeSimilarStyleNodes(last);
    }
  }

  // Queries the child Node at offset in this container.
  // The result may contain the found node or `null` if no node is found at specified offset.
  // ChildQuery.offset is set to relative offset within returned child node which points at
  // the same character position in the document as the original offset.
  NodePositionM queryChild(
    ContainerM container,
    int offset,
    bool inclusive,
  ) {
    if (offset < 0 || offset > container.charsNum) {
      return NodePositionM(null, 0);
    }

    for (final node in container.children) {
      final len = node.charsNum;

      if (offset < len || (inclusive && offset == len && node.isLast)) {
        return NodePositionM(node, offset);
      }

      offset -= len;
    }

    return NodePositionM(null, 0);
  }
}
