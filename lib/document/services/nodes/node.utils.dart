import '../../models/attributes/attribute.model.dart';
import '../../models/delta/delta.model.dart';
import '../../models/nodes/block.model.dart';
import '../../models/nodes/container.model.dart';
import '../../models/nodes/leaf.model.dart';
import '../../models/nodes/line.model.dart';
import '../../models/nodes/node.model.dart';
import '../../models/nodes/root.model.dart';
import '../../models/nodes/style.model.dart';
import 'block.utils.dart';
import 'container.utils.dart';
import 'leaf.utils.dart';
import 'line.utils.dart';
import 'styles.utils.dart';

final _contUtils = ContainerUtils();
final _lineUtils = LineUtils();
final _leafUtils = LeafUtils();
final _blockUtils = BlockUtils();
final _stylesUtils = StylesUtils();

class NodeUtils {
  void insert(
    NodeM? node,
    int index,
    Object data,
    StyleM? attributes,
  ) {
    // Line
    if (node is LineM) {
      _lineUtils.insert(node, index, data, attributes);

      // Container
    } else if (node is ContainerM) {
      _contUtils.insert(node, index, data, attributes);

      // Leaf
    } else if (node is LeafM) {
      _leafUtils.insert(node, index, data, attributes);
    }
  }

  void retain(
    NodeM? node,
    int index,
    int? length,
    StyleM? attributes,
  ) {
    // Line
    if (node is LineM) {
      _lineUtils.retain(node, index, length, attributes);

      // Container
    } else if (node is ContainerM) {
      _contUtils.retain(node, index, length, attributes);

      // Leaf
    } else if (node is LeafM) {
      _leafUtils.retain(node, index, length, attributes);
    }
  }

  void delete(
    NodeM? node,
    int index,
    int? length,
  ) {
    // Line
    if (node is LineM) {
      _lineUtils.delete(node, index, length);

      // Container
    } else if (node is ContainerM) {
      _contUtils.delete(node, index, length);

      // Leaf
    } else if (node is LeafM) {
      _leafUtils.delete(node, index, length);
    }
  }

  DeltaM toDelta(NodeM? node) {
    // Block
    if (node is BlockM) {
      return _blockUtils.toDelta(node);
    }

    // Line
    else if (node is LineM) {
      return _lineUtils.toDelta(node);

      // Leaf
    } else if (node is LeafM) {
      return _leafUtils.toDelta(node);
    }

    return DeltaM();
  }

  void mergeSimilarStyleNodes(NodeM? node) {
    // Block
    if (node is BlockM) {
      _blockUtils.mergeSimilarStyleNodes(node);

      // Leaf
    } else if (node is LeafM) {
      _leafUtils.mergeSimilarStyleNodes(node);
    }
  }

  // Offset in characters of this node in the document.
  int getDocumentOffset(NodeM node) {
    if (node.parent == null) {
      return getOffset(node);
    }

    final parentOffset =
        (node.parent is! RootM) ? getDocumentOffset(node.parent!) : 0;

    return parentOffset + getOffset(node);
  }

  // Offset in characters of this node relative to parent node.
  // To get offset of this node in the document see documentOffset.
  int getOffset(NodeM node) {
    var offset = 0;

    if (node.list == null || node.isFirst) {
      return offset;
    }

    var cur = node;

    do {
      cur = cur.previous!;
      offset += cur.charsNum;
    } while (!cur.isFirst);

    return offset;
  }

  void applyAttribute(NodeM node, AttributeM attribute) {
    node.style = _stylesUtils.merge(node.style, attribute);
  }

  // Returns `true` if this node contains character at specified offset in the document.
  bool containsOffset(NodeM node, int offset) {
    final docOffset = getDocumentOffset(node);
    return docOffset <= offset && offset < docOffset + node.charsNum;
  }
}
