import 'node.model.dart';

// Result of a NodeM child query in a ContainerM (line or block).
// Contains offset of character within the child node.
class NodePositionM {
  final NodeM? node;
  final int offset;

  NodePositionM(
    this.node,
    this.offset,
  );

  bool get isEmpty => node == null;

  bool get isNotEmpty => node != null;
}
