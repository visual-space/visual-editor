import 'dart:collection';

import '../attribute.model.dart';
import '../delta/delta.model.dart';
import '../style.model.dart';
import 'container.model.dart';
import 'root.model.dart';

// An abstract node in a document tree.
// Represents a segment of a Visual Editor document with specified offset and length.
// The offset property is relative to parent.
// See also documentOffset which provides absolute offset of this node within the document.
// The current parent node is exposed by the parent property.
// A node is considered mounted when the parent property is not `null`.
abstract class NodeM extends LinkedListEntry<NodeM> {
  // Current parent of this node. May be null if this node is not mounted.
  ContainerM? parent;

  StyleM get style => _style;
  StyleM _style = StyleM();

  // Returns `true` if this node is the first node in the parent list.
  bool get isFirst => list!.first == this;

  // Returns `true` if this node is the last node in the parent list.
  bool get isLast => list!.last == this;

  // Length of this node in characters.
  int get length;

  NodeM clone() => newInstance()..applyStyle(style);

  // Offset in characters of this node relative to parent node.
  // To get offset of this node in the document see documentOffset.
  int get offset {
    var offset = 0;

    if (list == null || isFirst) {
      return offset;
    }

    var cur = this;
    do {
      cur = cur.previous!;
      offset += cur.length;
    } while (!cur.isFirst);
    return offset;
  }

  // Offset in characters of this node in the document.
  int get documentOffset {
    if (parent == null) {
      return offset;
    }

    final parentOffset = (parent is! RootM) ? parent!.documentOffset : 0;

    return parentOffset + offset;
  }

  // Returns `true` if this node contains character at specified offset in the document.
  bool containsOffset(int offset) {
    final o = documentOffset;
    return o <= offset && offset < o + length;
  }

  void applyAttribute(AttributeM attribute) {
    _style = _style.merge(attribute);
  }

  void applyStyle(StyleM value) {
    _style = _style.mergeAll(value);
  }

  void clearStyle() {
    _style = StyleM();
  }

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

  void adjust() {
    /* no-op */
  }

  // === ABSTRACT METHODS ===

  NodeM newInstance();

  String toPlainText();

  DeltaM toDelta();

  void insert(int index, Object data, StyleM? style);

  void retain(int index, int? len, StyleM? style);

  void delete(int index, int? len);
}
