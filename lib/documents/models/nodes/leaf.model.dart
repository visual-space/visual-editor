import 'dart:math' as math;

import '../delta/delta.model.dart';
import '../style.model.dart';
import 'embed.model.dart';
import 'embeddable.model.dart';
import 'line.model.dart';
import 'node.model.dart';
import 'text.model.dart';

// A leaf in Visual Editor document tree.
abstract class LeafM extends NodeM {
  // Creates a new [Leaf] with specified [data].
  factory LeafM(Object data) {
    if (data is EmbeddableM) {
      return EmbedM(data);
    }

    final text = data as String;

    assert(text.isNotEmpty);

    return TextM(text);
  }

  LeafM.val(Object val) : _value = val;

  // Contents of this node, either a String if this is a [Text] or an [Embed] if this is an [BlockEmbed].
  Object get value => _value;
  Object _value;

  @override
  void applyStyle(StyleM value) {
    // TODO DOC: Not sure why we need to check if all styles are of one scope or the other
    assert(
      value.isInline || value.isIgnored || value.isEmpty,
      'Unable to apply Style to leaf: $value',
    );
    super.applyStyle(value);
  }

  @override
  LineM? get parent => super.parent as LineM?;

  @override
  int get length {
    if (_value is String) {
      return (_value as String).length;
    }

    // Return 1 for embedded object
    return 1;
  }

  @override
  DeltaM toDelta() {
    final data =
        _value is EmbeddableM ? (_value as EmbeddableM).toJson() : _value;

    return DeltaM()..insert(data, style.toJson());
  }

  @override
  void insert(int index, Object data, StyleM? style) {
    assert(index >= 0 && index <= length);

    final node = LeafM(data);

    if (index < length) {
      splitAt(index)!.insertBefore(node);
    } else {
      insertAfter(node);
    }

    node.format(style);
  }

  @override
  void retain(int index, int? len, StyleM? style) {
    if (style == null) {
      return;
    }

    final local = math.min(length - index, len!);
    final remain = len - local;
    final node = _isolate(index, local);

    if (remain > 0) {
      assert(node.next != null);
      node.next!.retain(0, remain, style);
    }

    node.format(style);
  }

  @override
  void delete(int index, int? len) {
    assert(index < length);

    final local = math.min(length - index, len!);
    final target = _isolate(index, local);
    final prev = target.previous as LeafM?;
    final next = target.next as LeafM?;
    target.unlink();
    final remain = len - local;

    if (remain > 0) {
      assert(next != null);
      next!.delete(0, remain);
    }

    if (prev != null) {
      prev.adjust();
    }
  }

  @override
  String toString() {
    final keys = style.keys.toList(growable: false)..sort();
    final styleKeys = keys.join();

    return '⟨$value⟩$styleKeys';
  }

  // Adjust this text node by merging it with adjacent nodes if they share the same style.
  @override
  void adjust() {
    if (this is EmbedM) {
      // Embed nodes cannot be merged with text nor other embeds.
      // In fact, there could be no two adjacent embeds on the same line
      // since an embed occupies an entire line.
      return;
    }

    // This is a text node and it can only be merged with other text nodes.
    var node = this as TextM;

    // Merging it with previous node if style is the same.
    final prev = node.previous;

    if (!node.isFirst && prev is TextM && prev.style == node.style) {
      prev._value = prev.value + node.value;
      node.unlink();
      node = prev;
    }

    // Merging it with next node if style is the same.
    final next = node.next;

    if (!node.isLast && next is TextM && next.style == node.style) {
      node._value = node.value + next.value;
      next.unlink();
    }
  }

  // Splits this leaf node at [index] and returns new node.
  // If this is the last node in its list and [index] equals this node's
  // length then this method returns `null` as there is nothing left to split.
  // If there is another leaf node after this one and [index] equals
  // this node's length then the next leaf node is returned.
  // If [index] equals to `0` then this node itself is returned unchanged.
  // In case a new node is actually split from this one, it inherits this node's style.
  LeafM? splitAt(int index) {
    assert(index >= 0 && index <= length);

    if (index == 0) {
      return this;
    }

    if (index == length) {
      return isLast ? null : next as LeafM?;
    }

    assert(this is TextM);
    final text = _value as String;
    _value = text.substring(0, index);
    final split = LeafM(text.substring(index))..applyStyle(style);
    insertAfter(split);

    return split;
  }

  // Cuts a leaf from [index] to the end of this node and returns new node in detached state (e.g. [mounted] returns `false`).
  // Splitting logic is identical to one described in [splitAt], meaning this method may return `null`.
  LeafM? cutAt(int index) {
    assert(index >= 0 && index <= length);
    final cut = splitAt(index);
    cut?.unlink();
    return cut;
  }

  // Formats this node and optimizes it with adjacent leaf nodes if needed.
  void format(StyleM? style) {
    if (style != null && style.isNotEmpty) {
      applyStyle(style);
    }

    adjust();
  }

  // Isolates a new leaf starting at [index] with specified [length].
  // Splitting logic is identical to one described in [splitAt], with one exception that it is
  // required for [index] to always be less than this node's length.
  // As a result this method always returns a [LeafNode] instance.
  // Returned node may still be the same as this node if provided [index] is `0`.
  LeafM _isolate(int index, int length) {
    assert(
      index >= 0 && index < this.length && (index + length <= this.length),
    );

    final target = splitAt(index)!..splitAt(length);

    return target;
  }
}