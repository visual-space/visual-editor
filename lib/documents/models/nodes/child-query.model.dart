import 'node.model.dart';

// Result of a child query in a [ContainerM].
class ChildQueryM {
  ChildQueryM(this.node, this.offset);

  // The child node if found, otherwise `null`.
  final NodeM? node;

  // Starting offset within the child [node] which points at the same
  // character in the document as the original offset passed to
  // [ContainerM.queryChild] method.
  final int offset;

  // Returns `true` if there is no child node found, e.g. [node] is `null`.
  bool get isEmpty => node == null;

  // Returns `true` [node] is not `null`.
  bool get isNotEmpty => node != null;
}
