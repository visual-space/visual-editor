import 'package:tuple/tuple.dart';

import '../../delta/models/delta.model.dart';
import '../../delta/models/operation.model.dart';
import '../../documents/models/attribute.model.dart';
import '../../documents/models/document.model.dart';
import '../../documents/models/nodes/block-embed.model.dart';
import '../../documents/models/style.model.dart';
import '../../documents/models/styling-attributes.dart';
import '../models/insert-rule.model.dart';

// Preserves line format when user splits the line into two.
// This rule ignores scenarios when the line is split on its edge,
// meaning a newline is inserted at the beginning or the end of a line.
class PreserveLineStyleOnSplitRule extends InsertRuleM {
  const PreserveLineStyleOnSplitRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    if (data is! String || data != '\n') {
      return null;
    }

    final itr = DeltaIterator(document);
    final before = itr.skip(index);

    if (before == null ||
        before.data is! String ||
        (before.data as String).endsWith('\n')) {
      return null;
    }

    final after = itr.next();

    if (after.data is! String || (after.data as String).startsWith('\n')) {
      return null;
    }

    final text = after.data as String;
    final delta = DeltaM()..retain(index + (len ?? 0));

    if (text.contains('\n')) {
      assert(after.isPlain);
      delta.insert('\n');
      return delta;
    }

    final nextNewLine = _getNextNewLine(itr);
    final attributes = nextNewLine.item1?.attributes;

    return delta..insert('\n', attributes);
  }
}

// Preserves block style when user inserts text containing newlines.
// This rule handles:
//   * inserting a new line in a block
//   * pasting text containing multiple lines of text in a block
// This rule may also be activated for changes triggered by auto-correct.
class PreserveBlockStyleOnInsertRule extends InsertRuleM {
  const PreserveBlockStyleOnInsertRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    if (data is! String || !data.contains('\n')) {
      // Only interested in text containing at least one newline character.
      return null;
    }

    final itr = DeltaIterator(document)..skip(index);

    // Look for the next newline.
    final nextNewLine = _getNextNewLine(itr);
    final lineStyle = StyleM.fromJson(
      nextNewLine.item1?.attributes ?? <String, dynamic>{},
    );
    final blockStyle = lineStyle.getBlocksExceptHeader();

    // Are we currently in a block? If not then ignore.
    if (blockStyle.isEmpty) {
      return null;
    }

    final resetStyle = <String, dynamic>{};

    // If current line had heading style applied to it we'll need to move this style to
    // the newly inserted line before it and reset style of the original line.
    if (lineStyle.containsKey(AttributeM.header.key)) {
      resetStyle.addAll(
        AttributeM.header.toJson(),
      );
    }

    // Go over each inserted line and ensure block style is applied.
    final lines = data.split('\n');
    final delta = DeltaM()..retain(index + (len ?? 0));

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.isNotEmpty) {
        delta.insert(line);
      }

      if (i == 0) {
        // The first line should inherit the lineStyle entirely.
        delta.insert('\n', lineStyle.toJson());
      } else if (i < lines.length - 1) {
        // We don't want to insert a newline after the last chunk of text, so -1
        final blockAttributes = blockStyle.isEmpty
            ? null
            : blockStyle.map<String, dynamic>(
                (_, attribute) =>
                    MapEntry<String, dynamic>(attribute.key, attribute.value),
              );
        delta.insert('\n', blockAttributes);
      }
    }

    // Reset style of the original newline character if needed.
    if (resetStyle.isNotEmpty) {
      delta
        ..retain(nextNewLine.item2!)
        ..retain((nextNewLine.item1!.data as String).indexOf('\n'))
        ..retain(1, resetStyle);
    }

    return delta;
  }
}

// Heuristic rule to exit current block when user inserts two consecutive newlines.
// This rule is only applied when the cursor is on the last line of a block.
// When the cursor is in the middle of a block we allow adding empty lines and preserving the block's style.
class AutoExitBlockRule extends InsertRuleM {
  const AutoExitBlockRule();

  bool _isEmptyLine(Operation? before, Operation? after) {
    if (before == null) {
      return true;
    }

    return before.data is String &&
        (before.data as String).endsWith('\n') &&
        after!.data is String &&
        (after.data as String).startsWith('\n');
  }

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    if (data is! String || data != '\n') {
      return null;
    }

    final itr = DeltaIterator(document);
    final prev = itr.skip(index), cur = itr.next();
    final blockStyle = StyleM.fromJson(cur.attributes).getBlockExceptHeader();

    // We are not in a block, ignore.
    if (cur.isPlain || blockStyle == null) {
      return null;
    }

    // We are not on an empty line, ignore.
    if (!_isEmptyLine(prev, cur)) {
      return null;
    }

    // We are on an empty line. Now we need to determine if we are on the last line of a block.
    // First check if `cur` length is greater than 1, this would indicate that it contains
    // $multiple newline characters which share the same style.
    // This would mean we are not on the last line yet.
    // `cur.value as String` is safe since we already called isEmptyLine and know it contains a newline
    if ((cur.value as String).length > 1) {
      // We are not on the last line of this block, ignore.
      return null;
    }

    // Keep looking for the next newline character to see if it shares the same block style as `cur`.
    final nextNewLine = _getNextNewLine(itr);
    if (nextNewLine.item1 != null &&
        nextNewLine.item1!.attributes != null &&
        StyleM.fromJson(nextNewLine.item1!.attributes).getBlockExceptHeader() ==
            blockStyle) {
      // We are not at the end of this block, ignore.
      return null;
    }

    // Here we now know that the line after `cur` is not in the same block
    // therefore we can exit this block.
    final attributes = cur.attributes ?? <String, dynamic>{};
    final k = attributes.keys.firstWhere(
      AttributeM.blockKeysExceptHeader.contains,
    );
    attributes[k] = null;

    // retain(1) should be '\n', set it with no attribute
    return DeltaM()
      ..retain(index + (len ?? 0))
      ..retain(1, attributes);
  }
}

// Resets format for a newly inserted line when insert occurred at the end of a line (right before a newline).
// This handles scenarios when a new line is added when at the end of a heading line.
// The newly added line should be a regular paragraph.
class ResetLineFormatOnNewLineRule extends InsertRuleM {
  const ResetLineFormatOnNewLineRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    if (data is! String || data != '\n') {
      return null;
    }

    final itr = DeltaIterator(document)..skip(index);
    final cur = itr.next();

    if (cur.data is! String || !(cur.data as String).startsWith('\n')) {
      return null;
    }

    Map<String, dynamic>? resetStyle;

    if (cur.attributes != null &&
        cur.attributes!.containsKey(AttributeM.header.key)) {
      resetStyle = AttributeM.header.toJson();
    }

    return DeltaM()
      ..retain(index + (len ?? 0))
      ..insert('\n', cur.attributes)
      ..retain(1, resetStyle)
      ..trim();
  }
}

// Handles all format operations which manipulate embeds.
// This rule wraps line breaks around video, not image.
class InsertEmbedsRule extends InsertRuleM {
  const InsertEmbedsRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    if (data is String) {
      return null;
    }

    assert(data is Map);

    if (!(data as Map).containsKey(BlockEmbedM.videoType)) {
      return null;
    }

    final delta = DeltaM()..retain(index + (len ?? 0));
    final itr = DeltaIterator(document);
    final prev = itr.skip(index), cur = itr.next();
    final textBefore = prev?.data is String ? prev!.data as String? : '';
    final textAfter = cur.data is String ? (cur.data as String?)! : '';
    final isNewlineBefore = prev == null || textBefore!.endsWith('\n');
    final isNewlineAfter = textAfter.startsWith('\n');

    if (isNewlineBefore && isNewlineAfter) {
      return delta..insert(data);
    }

    Map<String, dynamic>? lineStyle;

    if (textAfter.contains('\n')) {
      lineStyle = cur.attributes;
    } else {
      while (itr.hasNext) {
        final op = itr.next();
        if ((op.data is String ? op.data as String? : '')!.contains('\n')) {
          lineStyle = op.attributes;
          break;
        }
      }
    }

    if (!isNewlineBefore) {
      delta.insert('\n', lineStyle);
    }

    delta.insert(data);

    if (!isNewlineAfter) {
      delta.insert('\n');
    }

    return delta;
  }
}

// Applies link format to text segments within the inserted text that matches
// the URL pattern.
//
// The link attribute is applied as the user types.
class AutoFormatMultipleLinksRule extends InsertRuleM {
  const AutoFormatMultipleLinksRule();

  // Link pattern.
  //
  // This pattern is used to match a links within a text segment.
  //
  // It works for the following testing URLs:
  // www.google.com
  // http://google.com
  // https://www.google.com
  // http://beginner.example.edu/#act
  // https://birth.example.net/beds/ants.php#bait
  // http://example.com/babies
  // https://www.example.com/
  // https://attack.example.edu/?acoustics=blade&bed=bed
  // http://basketball.example.com/
  // https://birthday.example.com/birthday
  // http://www.example.com/
  // https://example.com/addition/action
  // http://example.com/
  // https://bite.example.net/#adjustment
  // http://www.example.net/badge.php?bedroom=anger
  // https://brass.example.com/?anger=branch&actor=amusement#adjustment
  // http://www.example.com/?action=birds&brass=apparatus
  // https://example.net/
  // URL generator tool (https://www.randomlists.com/urls) is used.
  static const _linkPattern =
      r'(https?:\/\/|www\.)[\w-\.]+\.[\w-\.]+(\/([\S]+)?)?';
  static final linkRegExp = RegExp(_linkPattern);

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    // Only format when inserting text.
    if (data is! String) return null;

    // Get current text.
    final entireText = DocumentM.fromDelta(document).toPlainText();

    // Get word before insertion.
    final leftWordPart = entireText
        // Keep all text before insertion.
        .substring(0, index)
        // Keep last paragraph.
        .split('\n')
        .last
        // Keep last word.
        .split(' ')
        .last
        .trimLeft();

    // Get word after insertion.
    final rightWordPart = entireText
        // Keep all text after insertion.
        .substring(index)
        // Keep first paragraph.
        .split('\n')
        .first
        // Keep first word.
        .split(' ')
        .first
        .trimRight();

    // Build the segment of affected words.
    final affectedWords = '$leftWordPart$data$rightWordPart';

    // Check for URL pattern.
    final matches = linkRegExp.allMatches(affectedWords);

    // If there are no matches, do not apply any format.
    if (matches.isEmpty) return null;

    // Build base delta.
    // The base delta is a simple insertion delta.
    final baseDelta = DeltaM()
      ..retain(index)
      ..insert(data);

    // Get unchanged text length.
    final unmodifiedLength = index - leftWordPart.length;

    // Create formatter delta.
    // The formatter delta will only include links formatting when needed.
    final formatterDelta = DeltaM()..retain(unmodifiedLength);

    var previousLinkEndRelativeIndex = 0;
    for (final match in matches) {
      // Get the size of the leading segment of text that is not part of the
      // link.
      final separationLength = match.start - previousLinkEndRelativeIndex;

      // Get the identified link.
      final link = affectedWords.substring(match.start, match.end);

      // Keep the leading segment of text and add link with its proper
      // attribute.
      formatterDelta
        ..retain(separationLength, AttributeM.link.toJson())
        ..retain(link.length, LinkAttributeM(link).toJson());

      // Update reference index.
      previousLinkEndRelativeIndex = match.end;
    }

    // Get remaining text length.
    final remainingLength = affectedWords.length - previousLinkEndRelativeIndex;

    // Remove links from remaining non-link text.
    formatterDelta.retain(remainingLength, AttributeM.link.toJson());

    // Build and return resulting change delta.
    return baseDelta.compose(formatterDelta);
  }
}

// Applies link format to text segment (which looks like a link) when user inserts space character after it.
class AutoFormatLinksRule extends InsertRuleM {
  const AutoFormatLinksRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    if (data is! String || data != ' ') {
      return null;
    }

    final itr = DeltaIterator(document);
    final prev = itr.skip(index);

    if (prev == null || prev.data is! String) {
      return null;
    }

    try {
      final cand = (prev.data as String).split('\n').last.split(' ').last;
      final link = Uri.parse(cand);

      if (!['https', 'http'].contains(link.scheme)) {
        return null;
      }

      final attributes = prev.attributes ?? <String, dynamic>{};

      if (attributes.containsKey(AttributeM.link.key)) {
        return null;
      }

      attributes.addAll(LinkAttributeM(link.toString()).toJson());

      return DeltaM()
        ..retain(index + (len ?? 0) - cand.length)
        ..retain(cand.length, attributes)
        ..insert(data, prev.attributes);
    } on FormatException {
      return null;
    }
  }
}

// Preserves inline styles when user inserts text inside formatted segment.
class PreserveInlineStylesRule extends InsertRuleM {
  const PreserveInlineStylesRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    if (data is! String || data.contains('\n')) {
      return null;
    }

    final itr = DeltaIterator(document);
    final prev = itr.skip(index);

    if (prev == null ||
        prev.data is! String ||
        (prev.data as String).contains('\n')) {
      return null;
    }

    final attributes = prev.attributes;
    final text = data;

    if (attributes == null || !attributes.containsKey(AttributeM.link.key)) {
      return DeltaM()
        ..retain(index + (len ?? 0))
        ..insert(text, attributes);
    }

    attributes.remove(AttributeM.link.key);
    final delta = DeltaM()
      ..retain(index + (len ?? 0))
      ..insert(text, attributes.isEmpty ? null : attributes);
    final next = itr.next();
    final nextAttributes = next.attributes ?? const <String, dynamic>{};

    if (!nextAttributes.containsKey(AttributeM.link.key)) {
      return delta;
    }

    if (attributes[AttributeM.link.key] == nextAttributes[AttributeM.link.key]) {
      return DeltaM()
        ..retain(index + (len ?? 0))
        ..insert(text, attributes);
    }

    return delta;
  }
}

// Fallback rule which simply inserts text as-is without any special handling.
class CatchAllInsertRule extends InsertRuleM {
  const CatchAllInsertRule();

  @override
  DeltaM applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    return DeltaM()
      ..retain(index + (len ?? 0))
      ..insert(data);
  }
}

Tuple2<Operation?, int?> _getNextNewLine(DeltaIterator iterator) {
  Operation op;

  for (var skipped = 0; iterator.hasNext; skipped += op.length!) {
    op = iterator.next();
    final lineBreak =
        (op.data is String ? op.data as String? : '')!.indexOf('\n');

    if (lineBreak >= 0) {
      return Tuple2(op, skipped);
    }
  }

  return const Tuple2(null, null);
}
