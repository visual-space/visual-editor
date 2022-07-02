import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:tuple/tuple.dart';

import '../attribute-scope.enum.dart';
import '../attribute.model.dart';
import '../delta/delta.model.dart';
import '../style.model.dart';
import 'block.model.dart';
import 'container.model.dart';
import 'embed.model.dart';
import 'embeddable.model.dart';
import 'leaf.model.dart';
import 'node.model.dart';
import 'text.model.dart';

// A line of rich text in a Editor document.
// Line serves as a container for Leafs, like Text and Embed.
// When a line contains an embed, it fully occupies the line, no other embeds or text nodes are allowed.
class LineM extends ContainerM<LeafM?> {
  @override
  LeafM get defaultChild => TextM();

  @override
  int get length => super.length + 1;

  // Returns `true` if this line contains an embedded object.
  bool get hasEmbed {
    return children.any((child) => child is EmbedM);
  }

  // Returns next Line or `null` if this is the last line in the document.
  LineM? get nextLine {
    if (!isLast) {
      return next is BlockM ? (next as BlockM).first as LineM? : next as LineM?;
    }

    if (parent is! BlockM) {
      return null;
    }

    if (parent!.isLast) {
      return null;
    }

    return parent!.next is BlockM
        ? (parent!.next as BlockM).first as LineM?
        : parent!.next as LineM?;
  }

  @override
  NodeM newInstance() => LineM();

  @override
  DeltaM toDelta() {
    final delta = children
        .map((child) => child.toDelta())
        .fold(DeltaM(), (dynamic a, b) => a.concat(b));
    var attributes = style;

    if (parent is BlockM) {
      final block = parent as BlockM;
      attributes = attributes.mergeAll(block.style);
    }
    delta.insert('\n', attributes.toJson());

    return delta;
  }

  @override
  String toPlainText() => '${super.toPlainText()}\n';

  @override
  String toString() {
    final body = children.join(' → ');
    final styleString = style.isNotEmpty ? ' $style' : '';

    return '¶ $body ⏎$styleString';
  }

  @override
  void insert(int index, Object data, StyleM? style) {
    if (data is EmbeddableM) {
      // We do not check whether this line already has any children here as inserting an embed
      // into a line with other text is acceptable from the Delta format perspective.
      // We rely on heuristic rules to ensure that embeds occupy an entire line.
      _insertSafe(index, data, style);
      return;
    }

    final text = data as String;
    final lineBreak = text.indexOf('\n');

    if (lineBreak < 0) {
      _insertSafe(index, text, style);
      // No need to update line or block format since those attributes can only
      // be attached to `\n` character and we already know it's not present.
      return;
    }

    final prefix = text.substring(0, lineBreak);
    _insertSafe(index, prefix, style);

    if (prefix.isNotEmpty) {
      index += prefix.length;
    }

    // Next line inherits our format.
    final nextLine = _getNextLine(index);

    // Reset our format and unwrap from a block if needed.
    clearStyle();

    if (parent is BlockM) {
      _unwrap();
    }

    // Now we can apply new format and re-layout.
    _format(style);

    // Continue with remaining part.
    final remain = text.substring(lineBreak + 1);
    nextLine.insert(0, remain, style);
  }

  @override
  void retain(int index, int? len, StyleM? style) {
    if (style == null) {
      return;
    }

    final thisLength = length;
    final local = math.min(thisLength - index, len!);
    // If index is at newline character then this is a line/block style update.
    final isLineFormat = (index + local == thisLength) && local == 1;

    if (isLineFormat) {
      assert(
          style.values.every((attr) =>
              attr.scope == AttributeScope.BLOCK ||
              attr.scope == AttributeScope.IGNORE),
          'It is not allowed to apply inline attributes to line itself.');
      _format(style);
    } else {
      // Otherwise forward to children as it's an inline format update.
      assert(style.values.every((attr) =>
          attr.scope == AttributeScope.INLINE ||
          attr.scope == AttributeScope.IGNORE));
      assert(index + local != thisLength);
      super.retain(index, local, style);
    }

    final remain = len - local;

    if (remain > 0) {
      assert(nextLine != null);
      nextLine!.retain(0, remain, style);
    }
  }

  @override
  void delete(int index, int? len) {
    final local = math.min(length - index, len!);
    // Line feed
    final isLFDeleted = index + local == length;

    if (isLFDeleted) {
      // Our newline character deleted with all style information.
      clearStyle();

      if (local > 1) {
        // Exclude newline character from delete range for children.
        super.delete(index, local - 1);
      }
    } else {
      super.delete(index, local);
    }

    final remaining = len - local;

    if (remaining > 0) {
      assert(nextLine != null);
      nextLine!.delete(0, remaining);
    }

    if (isLFDeleted && isNotEmpty) {
      // Since we lost our line-break and still have child text nodes those must migrate to the next line.
      // nextLine might have been unmounted since last assert so we need to check again we still have a line after us.
      assert(nextLine != null);

      // Move remaining children in this line to the next line so that all attributes of nextLine are preserved.
      nextLine!.moveChildToNewParent(this);
      moveChildToNewParent(nextLine);
    }

    if (isLFDeleted) {
      // Now we can remove this line.
      // Remember reference before un-linking.
      final block = parent!;
      unlink();
      block.adjust();
    }
  }

  // Formats this line.
  void _format(StyleM? newStyle) {
    if (newStyle == null || newStyle.isEmpty) {
      return;
    }

    applyStyle(newStyle);
    final blockStyle = newStyle.getBlockExceptHeader();

    // No block-level changes
    if (blockStyle == null) {
      return;
    }

    if (parent is BlockM) {
      final parentStyle = (parent as BlockM).style.getBlocksExceptHeader();

      // Ensure that we're only unwrapping the block only if we unset a single block format
      // in the `parentStyle` and there are no more block formats left to unset.
      if (blockStyle.value == null &&
          parentStyle.containsKey(blockStyle.key) &&
          parentStyle.length == 1) {
        _unwrap();
      } else if (!const MapEquality()
          .equals(newStyle.getBlocksExceptHeader(), parentStyle)) {
        _unwrap();

        // Block style now can contain multiple attributes
        if (newStyle.attributes.keys
            .any(AttributeM.exclusiveBlockKeys.contains)) {
          parentStyle.removeWhere(
              (key, attr) => AttributeM.exclusiveBlockKeys.contains(key));
        }

        parentStyle.removeWhere(
          (key, attr) => newStyle?.attributes.keys.contains(key) ?? false,
        );

        final parentStyleToMerge = StyleM.attr(parentStyle);
        newStyle = newStyle.mergeAll(parentStyleToMerge);
        _applyBlockStyles(newStyle);
      } // Else the same style, no-op.

    } else if (blockStyle.value != null) {
      // Only wrap with a new block if this is not an unset
      _applyBlockStyles(newStyle);
    }
  }

  void _applyBlockStyles(StyleM newStyle) {
    var block = BlockM();

    for (final style in newStyle.getBlocksExceptHeader().values) {
      block = block..applyAttribute(style);
    }

    _wrap(block);
    block.adjust();
  }

  // Wraps this line with new parent block.
  // This line can not be in a Block when this method is called.
  void _wrap(BlockM block) {
    assert(parent != null && parent is! BlockM);
    insertAfter(block);
    unlink();
    block.add(this);
  }

  // Unwraps this line from it's parent Block.
  // This method asserts if current parent of this line is not a Block.
  void _unwrap() {
    if (parent is! BlockM) {
      throw ArgumentError('Invalid parent');
    }

    final block = parent as BlockM;

    assert(block.children.contains(this));

    if (isFirst) {
      unlink();
      block.insertBefore(this);
    } else if (isLast) {
      unlink();
      block.insertAfter(this);
    } else {
      // Need to split this block into two as line is in the middle.
      final before = block.clone() as BlockM;
      block.insertBefore(before);

      var child = block.first as LineM;
      while (child != this) {
        child.unlink();
        before.add(child);
        child = block.first as LineM;
      }
      unlink();
      block.insertBefore(this);
    }
    block.adjust();
  }

  LineM _getNextLine(int index) {
    assert(index == 0 || (index > 0 && index < length));

    final line = clone() as LineM;
    insertAfter(line);

    if (index == length - 1) {
      return line;
    }

    final query = queryChild(index, false);

    while (!query.node!.isLast) {
      final next = (last as LeafM)..unlink();
      line.addFirst(next);
    }

    final child = query.node as LeafM;
    final cut = child.splitAt(query.offset);
    cut?.unlink();
    line.addFirst(cut);

    return line;
  }

  void _insertSafe(int index, Object data, StyleM? style) {
    assert(index == 0 || (index > 0 && index < length));

    if (data is String) {
      assert(!data.contains('\n'));

      if (data.isEmpty) {
        return;
      }
    }

    if (isEmpty) {
      final child = LeafM(data);
      add(child);
      child.format(style);
    } else {
      final result = queryChild(index, true);
      result.node!.insert(result.offset, data, style);
    }
  }

  // Returns style for specified text range.
  // Only attributes applied to all characters within this range are included in the result.
  // Inline and line level attributes are handled separately, e.g.:
  // - line attribute X is included in the result only if it exists for
  //   every line within this range (partially included lines are counted).
  // - inline attribute X is included in the result only if it exists
  //   for every character within this range (line-break characters excluded).
  // In essence, it is INTERSECTION of each individual segment's styles
  StyleM collectStyle(int offset, int len) {
    final local = math.min(length - offset, len);
    var result = StyleM();
    final excluded = <AttributeM>{};

    void _handle(StyleM style) {
      if (result.isEmpty) {
        excluded.addAll(style.values);
      } else {
        for (final attr in result.values) {
          if (!style.containsKey(attr.key)) {
            excluded.add(attr);
          }
        }
      }

      final remaining = style.removeAll(excluded);
      result = result.removeAll(excluded);
      result = result.mergeAll(remaining);
    }

    final data = queryChild(offset, true);
    var node = data.node as LeafM?;

    if (node != null) {
      result = result.mergeAll(node.style);
      var pos = node.length - data.offset;
      while (!node!.isLast && pos < local) {
        node = node.next as LeafM;
        _handle(node.style);
        pos += node.length;
      }
    }

    result = result.mergeAll(style);

    if (parent is BlockM) {
      final block = parent as BlockM;
      result = result.mergeAll(block.style);
    }

    final remaining = len - local;

    if (remaining > 0) {
      final rest = nextLine!.collectStyle(0, remaining);
      _handle(rest);
    }

    return result;
  }

  // Returns each node segment's offset in selection with its corresponding style as a list
  List<Tuple2<int, StyleM>> collectAllIndividualStyles(
    int offset,
    int len, {
    int beg = 0,
  }) {
    final local = math.min(length - offset, len);
    final result = <Tuple2<int, StyleM>>[];
    final data = queryChild(offset, true);
    var node = data.node as LeafM?;

    if (node != null) {
      var pos = 0;

      if (node is TextM) {
        pos = node.length - data.offset;
        result.add(Tuple2(beg, node.style));
      }

      while (!node!.isLast && pos < local) {
        node = node.next as LeafM;
        if (node is TextM) {
          result.add(Tuple2(pos + beg, node.style));
          pos += node.length;
        }
      }
    }

    // TODO: add line style and parent's block style
    final remaining = len - local;

    if (remaining > 0) {
      final rest =
          nextLine!.collectAllIndividualStyles(0, remaining, beg: local);
      result.addAll(rest);
    }

    return result;
  }

  // Returns all styles for any character within the specified text range.
  // In essence, it is UNION of each individual segment's styles
  List<StyleM> collectAllStyles(int offset, int len) {
    final local = math.min(length - offset, len);
    final result = <StyleM>[];
    final data = queryChild(offset, true);
    var node = data.node as LeafM?;

    if (node != null) {
      result.add(node.style);
      var pos = node.length - data.offset;

      while (!node!.isLast && pos < local) {
        node = node.next as LeafM;
        result.add(node.style);
        pos += node.length;
      }
    }

    result.add(style);

    if (parent is BlockM) {
      final block = parent as BlockM;
      result.add(block.style);
    }

    final remaining = len - local;

    if (remaining > 0) {
      final rest = nextLine!.collectAllStyles(0, remaining);
      result.addAll(rest);
    }

    return result;
  }

  // Returns plain text within the specified text range.
  String getPlainText(int offset, int len) {
    final plainText = StringBuffer();
    _getPlainText(offset, len, plainText);
    return plainText.toString();
  }

  int _getNodeText(LeafM node, StringBuffer buffer, int offset, int remaining) {
    final text = node.toPlainText();

    if (text == EmbedM.kObjectReplacementCharacter) {
      return remaining - node.length;
    }

    final end = math.min(offset + remaining, text.length);
    buffer.write(text.substring(offset, end));

    return remaining - (end - offset);
  }

  int _getPlainText(
    int offset,
    int len,
    StringBuffer plainText,
  ) {
    var _len = len;
    final data = queryChild(offset, true);
    var node = data.node as LeafM?;

    while (_len > 0) {
      if (node == null) {
        // Blank line
        plainText.write('\n');
        _len -= 1;
      } else {
        _len = _getNodeText(node, plainText, offset - node.offset, _len);

        while (!node!.isLast && _len > 0) {
          node = node.next as LeafM;
          _len = _getNodeText(node, plainText, 0, _len);
        }

        if (_len > 0) {
          // End of this line
          plainText.write('\n');
          _len -= 1;
        }
      }

      if (_len > 0) {
        _len = nextLine!._getPlainText(0, _len, plainText);
      }
    }

    return _len;
  }
}
