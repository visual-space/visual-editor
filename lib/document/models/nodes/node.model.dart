import 'dart:collection';

import '../../services/nodes/styles.utils.dart';
import 'container.model.dart';
import 'style.model.dart';

final _stylesUtils = StylesUtils();

// An abstract node in a document tree.
// Represents a fragment of a document that has the same styling attributes.
// The offset property is relative to parent.
// documentOffset provides absolute offset of this node within the document.
// A node is considered mounted when the parent property is not `null`.
abstract class NodeM extends LinkedListEntry<NodeM> {
  ContainerM? parent;
  StyleM style = StyleM();

  // === QUERIES ===

  NodeM newInstance();

  String toPlainText();

  bool get isFirst => list!.first == this;

  bool get isLast => list!.last == this;

  int get charsNum;

  // === EDIT OPERATIONS ===

  NodeM clone() => newInstance()..applyStyle(style);

  void applyStyle(StyleM value) {
    style = _stylesUtils.mergeAll(style, value);
  }

  void clearStyle() {
    style = StyleM();
  }

  // === LINKING ===

  @override
  void insertBefore(NodeM entry) {
    assert(entry.parent == null && parent != null);
    entry.parent = parent;
    super.insertBefore(entry);
  }

  @override
  void insertAfter(NodeM entry) {
    assert(entry.parent == null && parent != null);
    entry.parent = parent;
    super.insertAfter(entry);
  }

  @override
  void unlink() {
    assert(parent != null);
    parent = null;
    super.unlink();
  }
}
