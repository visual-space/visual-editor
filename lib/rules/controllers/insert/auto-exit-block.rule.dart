import '../../../delta/controllers/delta-iterator.controller.dart';
import '../../../delta/models/delta.model.dart';
import '../../../delta/models/operation.model.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/style.model.dart';
import '../../models/insert-rule.model.dart';
import '../../models/rules.utils.dart';

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
    final nextNewLine = getNextNewLine(itr);
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
