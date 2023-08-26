import '../../../document/controllers/delta.iterator.dart';
import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/attributes/attributes-types.model.dart';
import '../../../document/models/delta/delta.model.dart';
import '../../../document/models/delta/operation.model.dart';
import '../../../document/services/delta.utils.dart';
import '../../../document/services/nodes/styles.utils.dart';
import '../../models/insert-rule.model.dart';
import '../../models/rules.utils.dart';

final _stylesUtils = StylesUtils();

// Heuristic rule to exit current block when user inserts two consecutive newlines.
// This rule is only applied when the cursor is on the last line of a block.
// When the cursor is in the middle of a block we allow adding empty lines and preserving the block's style.
// For example, if you are in bullet list, pressing enter once will create a new bullet,
// pressing enter twice will terminate the bullet list.
// The same happens for any other block type (indents, code block, etc).
class AutoExitBlockRule extends InsertRuleM {
  final _du = DeltaUtils();

  AutoExitBlockRule();

  bool _isEmptyLine(OperationM? before, OperationM? after) {
    if (before == null) {
      return true;
    }

    return before.data is String && (before.data as String).endsWith('\n') && after!.data is String && (after.data as String).startsWith('\n');
  }

  @override
  DeltaM? applyRule(
    DeltaM docDelta,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
    String plainText = '',
  }) {
    if (data is! String || data != '\n') {
      return null;
    }

    final currItr = DeltaIterator(docDelta);
    final prev = currItr.skip(index);
    final curr = currItr.next();
    final style = _stylesUtils.fromJson(curr.attributes);
    final blockStyle = _stylesUtils.getBlockExceptHeader(style);

    // We are not in a block, ignore.
    if (curr.isPlain || blockStyle == null) {
      return null;
    }

    // We are not on an empty line, ignore.
    if (!_isEmptyLine(prev, curr)) {
      return null;
    }

    // We are on an empty line. Now we need to determine if we are on the last line of a block.
    // First check if `cur` length is greater than 1, this would indicate that it contains
    // $multiple newline characters which share the same style.
    // This would mean we are not on the last line yet.
    // `cur.value as String` is safe since we already called isEmptyLine and know it contains a newline
    if ((curr.value as String).length > 1) {
      // We are not on the last line of this block, ignore.
      return null;
    }

    // Keep looking for the next newline character to see if it shares the same block style as `cur`.
    final nextNewLine = getNextNewLine(currItr);
    final nStyle = _stylesUtils.fromJson(nextNewLine.operation!.attributes);
    final nextStyle = _stylesUtils.getBlockExceptHeader(nStyle);

    if (nextNewLine.operation != null && nextNewLine.operation!.attributes != null && nextStyle == blockStyle) {
      // We are not at the end of this block, ignore.
      return null;
    }

    // Here we now know that the line after `cur` is not in the same block
    // therefore we can exit this block.
    final attributes = curr.attributes ?? <String, dynamic>{};
    final k = attributes.keys.firstWhere(AttributesTypesM.blockKeysExceptHeader.contains);
    attributes[k] = null;

    // retain(1) should be '\n', set it with no attribute
    final changeDelta = DeltaM();

    _du.retain(changeDelta, index + (len ?? 0));
    _du.retain(changeDelta, 1, attributes);

    return changeDelta;
  }
}
