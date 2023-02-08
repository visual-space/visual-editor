import 'dart:math' as math;

import '../../models/delta/delta.model.dart';
import '../../models/nodes/embed-node.model.dart';
import '../../models/nodes/embed.model.dart';
import '../../models/nodes/leaf.model.dart';
import '../../models/nodes/style.model.dart';
import '../../models/nodes/text.model.dart';
import '../delta.utils.dart';

final _du = DeltaUtils();

class LeafUtils {
  // Creates a new Leaf with specified data.
  LeafM newLeaf(Object data) {
    if (data is EmbedM) {
      return EmbedNodeM(data);
    }

    final text = data as String;

    assert(text.isNotEmpty);

    return TextM(text);
  }

  void insert(LeafM leaf, int index, Object data, StyleM? style) {
    assert(index >= 0 && index <= leaf.charsNum);

    final node = LeafM(data);

    if (index < leaf.charsNum) {
      splitAt(leaf, index)!.insertBefore(node);
    } else {
      leaf.insertAfter(node);
    }

    format(node, style);
  }

  void retain(LeafM leaf, int index, int? len, StyleM? style) {
    if (style == null) {
      return;
    }

    final local = math.min(leaf.charsNum - index, len!);
    final remain = len - local;
    final node = _isolate(leaf, index, local);

    if (remain > 0) {
      assert(node.next != null);
      retain(node.next! as LeafM, 0, remain, style);
    }

    format(node, style);
  }

  void delete(LeafM leaf, int index, int? len) {
    assert(index < leaf.charsNum);

    final local = math.min(leaf.charsNum - index, len!);
    final target = _isolate(leaf, index, local);
    final prev = target.previous as LeafM?;
    final next = target.next as LeafM?;
    target.unlink();
    final remain = len - local;

    if (remain > 0) {
      assert(next != null);
      delete(next!, 0, remain);
    }

    if (prev != null) {
      mergeSimilarStyleNodes(prev);
    }
  }

  DeltaM toDelta(LeafM leaf) {
    final val = leaf.value;
    final deltaRes = DeltaM();
    final value = val is EmbedM ? val.toJson() : val;

    _du.insert(deltaRes, value, leaf.style.toJson());

    return deltaRes;
  }

  // Adjust this text node by merging it with adjacent nodes if they share the same style.
  void mergeSimilarStyleNodes(LeafM leaf) {
    if (leaf is EmbedNodeM) {
      // Embed nodes cannot be merged with text nor other embeds.
      // In fact, there could be no two adjacent embeds on the same line
      // since an embed occupies an entire line.
      return;
    }

    // This is a text node and it can only be merged with other text nodes.
    var text = leaf as TextM;

    // Merging it with previous node if style is the same.
    final prev = text.previous;

    if (!text.isFirst && prev is TextM && prev.style == text.style) {
      prev.value = prev.value + text.value;
      text.unlink();
      text = prev;
    }

    // Merging it with next node if style is the same.
    final next = text.next;

    if (!text.isLast && next is TextM && next.style == text.style) {
      text.value = text.value + next.value;
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
  LeafM? splitAt(LeafM leaf, int index) {
    assert(index >= 0 && index <= leaf.charsNum);

    if (index == 0) {
      return leaf;
    }

    if (index == leaf.charsNum) {
      return leaf.isLast ? null : leaf.next as LeafM?;
    }

    assert(leaf is TextM);

    final text = leaf.value as String;
    leaf.value = text.substring(0, index);
    final split = LeafM(text.substring(index))..applyStyle(leaf.style);
    leaf.insertAfter(split);

    return split;
  }

  // Cuts a leaf from [index] to the end of this node and returns new node in detached state (e.g. [mounted] returns `false`).
  // Splitting logic is identical to one described in [splitAt], meaning this method may return `null`.
  LeafM? cutAt(LeafM leaf, int index) {
    assert(index >= 0 && index <= leaf.charsNum);

    final cut = splitAt(leaf, index);
    cut?.unlink();

    return cut;
  }

  // Formats this node and optimizes it with adjacent leaf nodes if needed.
  void format(LeafM leaf, StyleM? style) {
    if (style != null && style.isNotEmpty) {
      leaf.applyStyle(style);
    }

    mergeSimilarStyleNodes(leaf);
  }

  int getCharsNumber(LeafM leaf) {
    final val = leaf.value;

    if (val is String) {
      return val.length;
    }

    // Return 1 for embedded object
    return 1;
  }

  String leafToString(LeafM leaf) {
    final keys = leaf.style.keys.toList(growable: false)..sort();
    final styleKeys = keys.join();

    return '⟨${leaf.value}⟩$styleKeys';
  }

  // === PRIVATE ===

  // Isolates a new leaf starting at [index] with specified [length].
  // Splitting logic is identical to one described in [splitAt], with one exception that it is
  // required for [index] to always be less than this node's length.
  // As a result this method always returns a [LeafNode] instance.
  // Returned node may still be the same as this node if provided [index] is `0`.
  LeafM _isolate(LeafM leaf, int index, int length) {
    assert(
      index >= 0 && index < leaf.charsNum && (index + length <= leaf.charsNum),
      'index param "$index" is not a valid value for the isolate() method',
    );

    final targetLeft = splitAt(leaf, index);
    final _targetLeft = targetLeft;
    final targetRight = splitAt(_targetLeft!, length);

    return targetLeft ?? targetRight!;
  }
}
