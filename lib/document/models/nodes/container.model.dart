import 'dart:collection';

import 'node.model.dart';

// Container can accommodate other document nodes.
// Delegates insert, retain and delete operations to children nodes.
// For each operation container looks for a child at specified
// index position and forwards operation to that child.
// Most of the operation handling logic is implemented by Line and Text.
abstract class ContainerM<T extends NodeM?> extends NodeM {
  final LinkedList<NodeM> _children = LinkedList<NodeM>();

  // === QUERIES ===

  LinkedList<NodeM> get children => _children;

  int get childCount => _children.length;

  NodeM get first => _children.first;

  NodeM get last => _children.last;

  bool get isEmpty => _children.isEmpty;

  bool get isNotEmpty => _children.isNotEmpty;

  // Returns an instance of default child for this container node.
  // Always returns fresh instance.
  T get defaultChild;

  @override
  String toPlainText() => children.map((child) => child.toPlainText()).join();

  @override
  int get charsNum => _children.fold(0, (cur, node) => cur + node.charsNum);

  @override
  String toString() => _children.join('\n');

}
