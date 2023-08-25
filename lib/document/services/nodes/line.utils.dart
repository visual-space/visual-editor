import 'dart:math' as math;

import 'package:collection/collection.dart';

import '../../models/attributes/attribute-scope.enum.dart';
import '../../models/attributes/attribute.model.dart';
import '../../models/attributes/attributes-types.model.dart';
import '../../models/attributes/paste-style.model.dart';
import '../../models/delta/delta.model.dart';
import '../../models/nodes/block.model.dart';
import '../../models/nodes/embed-node.model.dart';
import '../../models/nodes/embed.model.dart';
import '../../models/nodes/leaf.model.dart';
import '../../models/nodes/line.model.dart';
import '../../models/nodes/style.model.dart';
import '../../models/nodes/text.model.dart';
import '../delta.utils.dart';
import 'block.utils.dart';
import 'container.utils.dart';
import 'leaf.utils.dart';
import 'node.utils.dart';
import 'styles.utils.dart';

final _du = DeltaUtils();
final _contUtils = ContainerUtils();
final _nodeUtils = NodeUtils();
final _leafUtils = LeafUtils();
final _blockUtils = BlockUtils();
final _stylesUtils = StylesUtils();

class LineUtils {
  // === DOC EDITING OPS ===

  // Inserting text (string) in a LineM model.
  // Note that "\n" is used to mark the break line character.
  // When a new text is inserted in an existing line it might contain multiple break lines \n.
  // For each of these break lines this method slices the string in half, ingests the suffix as own text
  // and passes the remainder text to a new line by self invoking.
  // The entire string is chopped into multiple models. If you have 3 break lines expect to see 4 LineM.
  // Once all the break lines are consumed the method ends recursion.
  // All the new LineM models are linked to the previous LineM.
  // This means that in the final modeled nodes list you wont see the \n symbol.
  // You will only see LineM models containing the substrings in between \n chars.
  void insert(LineM line, int index, Object data, StyleM? style) {
    if (data is EmbedM) {
      // We do not check whether this line already has any children here as inserting an embed
      // into a line with other text is acceptable from the Delta format perspective.
      // We rely on heuristic rules to ensure that embeds occupy an entire line.
      _insertSafe(line, index, data, style);
      return;
    }

    final text = data as String;
    final lineBreak = text.indexOf('\n');

    final isLastLine = lineBreak < 0;
    if (isLastLine) {
      _insertSafe(line, index, text, style);
      // No need to update line or block format since those attributes can only
      // be attached to `\n` character and we already know it's not present.
      return;
    }

    final prefix = text.substring(0, lineBreak);
    _insertSafe(line, index, prefix, style);

    if (prefix.isNotEmpty) {
      index += prefix.length;
    }

    // Next line inherits our format.
    final nextLine = _getNextLineClone(line, index);

    // Reset our format and unwrap from a block if needed.
    line.clearStyle();

    if (line.parent is BlockM) {
      _unwrap(line);
    }

    // Now we can apply new format and re-layout.
    _format(line, style);

    // Continue with remaining part.
    final remain = text.substring(lineBreak + 1);
    insert(nextLine, 0, remain, style);
  }

  void retain(LineM line, int index, int? len, StyleM? style) {
    if (style == null) {
      return;
    }

    final local = math.min(line.charsNum - index, len!);

    // If index is at newline character then this is a line/block style update.
    final isLineFormat = (index + local == line.charsNum) && local == 1;

    if (isLineFormat) {
      assert(
        style.values.every((attr) =>
            attr.scope == AttributeScope.BLOCK ||
            attr.scope == AttributeScope.IGNORE),
        'It is not allowed to apply inline attributes to line itself.',
      );
      _format(line, style);
    } else {
      // Otherwise forward to children as it's an inline format update.
      assert(
        style.values.every((attr) =>
            attr.scope == AttributeScope.INLINE ||
            attr.scope == AttributeScope.IGNORE),
      );
      assert(index + local != line.charsNum);

      _contUtils.retain(line, index, local, style);
    }

    final remain = len - local;

    if (remain > 0) {
      assert(_getNextLine(line) != null);
      retain(_getNextLine(line)!, 0, remain, style);
    }
  }

  void delete(LineM line, int index, int? len) {
    final local = math.min(line.charsNum - index, len!);
    // Line feed
    final isLFDeleted = index + local == line.charsNum;

    if (isLFDeleted) {
      // Our newline character deleted with all style information.
      line.clearStyle();

      if (local > 1) {
        // Exclude newline character from delete range for children.
        _contUtils.delete(line, index, local - 1);
      }
    } else {
      _contUtils.delete(line, index, local);
    }

    final remaining = len - local;

    if (remaining > 0) {
      assert(_getNextLine(line) != null);
      delete(_getNextLine(line)!, 0, remaining);
    }

    if (isLFDeleted && line.isNotEmpty) {
      // Since we lost our line-break and still have child text nodes those must migrate to the next line.
      // nextLine might have been unmounted since last assert so we need to check again we still have a line after us.
      assert(_getNextLine(line) != null);

      // Move remaining children in this line to the next line so that all attributes of nextLine are preserved.
      _contUtils.moveChildToNewParent(_getNextLine(line)!, line);
      _contUtils.moveChildToNewParent(line, _getNextLine(line));
    }

    if (isLFDeleted) {
      // Now we can remove this line.
      // Remember reference before un-linking.
      final block = line.parent!;

      line.unlink();
      _nodeUtils.mergeSimilarStyleNodes(block);
    }
  }

  // === UTILS ===

  // Returns plain text within the specified text range.
  String getPlainText(LineM line, int offset, int len) {
    final plainText = StringBuffer();
    _getPlainText(line, offset, len, plainText);
    return plainText.toString();
  }

  DeltaM toDelta(LineM line) {
    final currDelta = line.children
        .map(_nodeUtils.toDelta)
        .fold(DeltaM(), _du.concat);
    var attributes = line.style;

    if (line.parent is BlockM) {
      final block = line.parent as BlockM;
      attributes = _stylesUtils.mergeAll(attributes, block.style);
    }
    _du.insert(currDelta, '\n', attributes.toJson());

    return currDelta;
  }

  String lineToString(LineM line) {
    final body = line.children.join(' → ');
    final styleString = line.style.isNotEmpty ? ' ${line.style}' : '';

    return '¶ $body ⏎$styleString';
  }

  // === STYLES ===

  // Returns style for specified text range.
  // Only attributes applied to all characters within this range are included in the result.
  // Inline and line level attributes are handled separately, e.g.:
  // - line attribute X is included in the result only if it exists for
  //   every line within this range (partially included lines are counted).
  // - inline attribute X is included in the result only if it exists
  //   for every character within this range (line-break characters excluded).
  // In essence, it is INTERSECTION of each individual segment's styles
  StyleM collectStyle(LineM line, int offset, int length) {
    final local = math.min(line.charsNum - offset, length);
    var resStyle = StyleM();
    final excluded = <AttributeM>{};

    void _handle(StyleM style) {
      if (resStyle.isEmpty) {
        excluded.addAll(style.values);
      } else {
        for (final attr in resStyle.values) {
          if (!style.containsKey(attr.key)) {
            excluded.add(attr);
          }
        }
      }

      final remaining = _stylesUtils.removeAll(style, excluded);
      resStyle = _stylesUtils.removeAll(resStyle, excluded);
      resStyle = _stylesUtils.mergeAll(resStyle, remaining);
    }

    final data = _contUtils.queryChild(line, offset, true);
    var node = data.node as LeafM?;

    if (node != null) {
      resStyle = _stylesUtils.mergeAll(resStyle, node.style);
      var pos = node.charsNum - data.offset;

      while (!node!.isLast && pos < local) {
        node = node.next as LeafM;
        _handle(node.style);
        pos += node.charsNum;
      }
    }

    resStyle = _stylesUtils.mergeAll(resStyle, line.style);

    if (line.parent is BlockM) {
      final block = line.parent as BlockM;
      resStyle = _stylesUtils.mergeAll(resStyle, block.style);
    }

    final remaining = length - local;

    if (remaining > 0) {
      final nextLine = _getNextLine(line)!;
      final rest = collectStyle(nextLine, 0, remaining);

      _handle(rest);
    }

    return resStyle;
  }

  // Returns each node segment's offset in selection with its corresponding style as a list
  List<PasteStyleM> collectAllIndividualStyles(
    LineM line,
    int offset,
    int length, {
    int beg = 0,
  }) {
    final local = math.min(line.charsNum - offset, length);
    final result = <PasteStyleM>[];
    final data = _contUtils.queryChild(line, offset, true);
    var node = data.node as LeafM?;

    if (node != null) {
      var pos = 0;

      if (node is TextM) {
        pos = node.charsNum - data.offset;
        result.add(PasteStyleM(beg, node.style));
      }

      while (!node!.isLast && pos < local) {
        node = node.next as LeafM;

        if (node is TextM) {
          result.add(PasteStyleM(pos + beg, node.style));
          pos += node.charsNum;
        }
      }
    }

    // TODO: add line style and parent's block style
    final remaining = length - local;

    if (remaining > 0) {
      final nextLine = _getNextLine(line)!;
      final rest = collectAllIndividualStyles(
        nextLine,
        0,
        remaining,
        beg: local,
      );
      result.addAll(rest);
    }

    return result;
  }

  // Returns all styles for any character within the specified text range.
  // In essence, it is UNION of each individual segment's styles
  List<StyleM> collectAllStyles(LineM line, int offset, int length) {
    final local = math.min(line.charsNum - offset, length);
    final result = <StyleM>[];
    final data = _contUtils.queryChild(line, offset, true);
    var node = data.node as LeafM?;

    if (node != null) {
      result.add(node.style);
      var pos = node.charsNum - data.offset;

      while (!node!.isLast && pos < local) {
        node = node.next as LeafM;
        result.add(node.style);
        pos += node.charsNum;
      }
    }

    result.add(line.style);

    if (line.parent is BlockM) {
      final block = line.parent as BlockM;
      result.add(block.style);
    }

    final remaining = length - local;

    if (remaining > 0) {
      final nextLine = _getNextLine(line)!;
      final rest = collectAllStyles(nextLine, 0, remaining);
      result.addAll(rest);
    }

    return result;
  }

  // === PRIVATE ===

  // Returns next Line or `null` if this is the last line in the document.
  LineM? _getNextLine(LineM line) {
    if (!line.isLast) {
      return line.next is BlockM
          ? (line.next as BlockM).first as LineM?
          : line.next as LineM?;
    }

    if (line.parent is! BlockM) {
      return null;
    }

    if (line.parent!.isLast) {
      return null;
    }

    return line.parent!.next is BlockM
        ? (line.parent!.next as BlockM).first as LineM?
        : line.parent!.next as LineM?;
  }

  // Splits a new line from the existing line at the requested index.
  // Inserts the old line after after the new line
  LineM _getNextLineClone(LineM line, int index) {
    assert(index == 0 || (index > 0 && index < line.charsNum));

    final lineClone = line.clone() as LineM;
    line.insertAfter(lineClone);

    if (index == line.charsNum - 1) {
      return lineClone;
    }

    final query = _contUtils.queryChild(line, index, false);

    while (!query.node!.isLast) {
      final next = (line.last as LeafM)..unlink();
      _contUtils.addFirst(lineClone, next);
    }

    final child = query.node as LeafM;
    final cut = _leafUtils.splitAt(child, query.offset);
    cut?.unlink();
    _contUtils.addFirst(lineClone, cut);

    return lineClone;
  }

  int _getPlainText(
    LineM line,
    int offset,
    int len,
    StringBuffer plainText,
  ) {
    var _len = len;
    final data = _contUtils.queryChild(line, offset, true);
    var node = data.node as LeafM?;

    while (_len > 0) {
      if (node == null) {
        // Blank line
        plainText.write('\n');
        _len -= 1;
      } else {
        final _offset = offset - _nodeUtils.getOffset(node);
        _len = _getNodeText(node, plainText, _offset, _len);

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
        final nextLine = _getNextLine(line)!;
        _len = _getPlainText(nextLine, 0, _len, plainText);
      }
    }

    return _len;
  }

  int _getNodeText(
    LeafM node,
    StringBuffer buffer,
    int offset,
    int remaining,
  ) {
    final text = node.toPlainText();

    if (text == EmbedNodeM.kObjectReplacementCharacter) {
      return remaining - node.charsNum;
    }

    final end = math.min(offset + remaining, text.length);
    buffer.write(text.substring(offset, end));

    return remaining - (end - offset);
  }

  // Formats this line.
  void _format(LineM line, StyleM? newStyle) {
    if (newStyle == null || newStyle.isEmpty) {
      return;
    }

    line.applyStyle(newStyle);
    final blockStyle = _stylesUtils.getBlockExceptHeader(newStyle);

    // No block-level changes
    if (blockStyle == null) {
      return;
    }

    if (line.parent is BlockM) {
      final style = (line.parent as BlockM).style;
      final parentStyle = _stylesUtils.getBlocksExceptHeader(style);

      // Ensure that we're only unwrapping the block only if we unset a single block format
      // in the `parentStyle` and there are no more block formats left to unset.
      if (blockStyle.value == null &&
          parentStyle.containsKey(blockStyle.key) &&
          parentStyle.length == 1) {
        _unwrap(line);
      } else if (!const MapEquality()
          .equals(_stylesUtils.getBlocksExceptHeader(newStyle), parentStyle)) {
        _unwrap(line);

        // Block style now can contain multiple attributes
        if (newStyle.attributes.keys.any(
          AttributesTypesM.exclusiveBlockKeys.contains,
        )) {
          parentStyle.removeWhere(
            (key, attr) => AttributesTypesM.exclusiveBlockKeys.contains(key),
          );
        }

        parentStyle.removeWhere(
          (key, attr) => newStyle?.attributes.keys.contains(key) ?? false,
        );

        final parentStyleToMerge = StyleM.attr(parentStyle);
        newStyle = _stylesUtils.mergeAll(newStyle, parentStyleToMerge);
        _applyBlockStyles(line, newStyle);
      } // Else the same style, no-op.

    } else if (blockStyle.value != null) {
      // Only wrap with a new block if this is not an unset
      _applyBlockStyles(line, newStyle);
    }
  }

  void _applyBlockStyles(LineM line, StyleM newStyle) {
    final block = BlockM();
    final values = _stylesUtils.getBlocksExceptHeader(newStyle).values;

    for (final style in values) {
      _nodeUtils.applyAttribute(block, style);
    }

    _wrap(line, block);
    _blockUtils.mergeSimilarStyleNodes(block);
  }

  // Wraps this line with new parent block.
  // This line can not be in a Block when this method is called.
  void _wrap(LineM line, BlockM block) {
    assert(line.parent != null && line.parent is! BlockM);

    line.insertAfter(block);
    line.unlink();
    _contUtils.add(block, line);
  }

  // Unwraps this line from it's parent Block.
  // This method asserts if current parent of this line is not a Block.
  void _unwrap(LineM line) {
    if (line.parent is! BlockM) {
      throw ArgumentError('Invalid parent');
    }

    final block = line.parent as BlockM;

    assert(block.children.contains(line));

    if (line.isFirst) {
      line.unlink();
      block.insertBefore(line);
    } else if (line.isLast) {
      line.unlink();
      block.insertAfter(line);
    } else {
      // Need to split this block into two as line is in the middle.
      final before = block.clone() as BlockM;

      block.insertBefore(before);

      var child = block.first as LineM;

      while (child != line) {
        child.unlink();
        _contUtils.add(before, child);
        child = block.first as LineM;
      }

      line.unlink();
      block.insertBefore(line);
    }

    _blockUtils.mergeSimilarStyleNodes(block);
  }

  // If data is empty the method terminates early (there's nothing to do).
  // If a line is empty then we add an empty leaf.
  // Otherwise we add the desired line.
  // Prevents invalid states of the document.
  void _insertSafe(
    LineM line,
    int index,
    Object data,
    StyleM? style,
  ) {
    assert(index == 0 || (index > 0 && index < line.charsNum));

    if (data is String) {
      assert(!data.contains('\n'));

      if (data.isEmpty) {
        return;
      }
    }

    if (line.isEmpty) {
      final child = LeafM(data);

      _contUtils.add(line, child);
      _leafUtils.format(child, style);
    } else {
      final result = _contUtils.queryChild(line, index, true);

      _nodeUtils.insert(result.node, result.offset, data, style);
    }
  }
}
