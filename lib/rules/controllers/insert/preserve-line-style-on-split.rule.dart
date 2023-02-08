import '../../../document/controllers/delta.iterator.dart';
import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/delta/delta.model.dart';
import '../../../document/services/delta.utils.dart';
import '../../models/insert-rule.model.dart';
import '../../models/rules.utils.dart';

// Preserves line format when user splits the line into two.
// This rule ignores scenarios when the line is split on its edge,
// meaning a newline is inserted at the beginning or the end of a line.
class PreserveLineStyleOnSplitRule extends InsertRuleM {
  final _du = DeltaUtils();

  PreserveLineStyleOnSplitRule();

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
    final before = currItr.skip(index);

    if (before == null ||
        before.data is! String ||
        (before.data as String).endsWith('\n')) {
      return null;
    }

    final after = currItr.next();

    if (after.data is! String || (after.data as String).startsWith('\n')) {
      return null;
    }

    final text = after.data as String;
    final changeDelta = DeltaM();
    _du.retain(changeDelta, index + (len ?? 0));

    if (text.contains('\n')) {
      assert(after.isPlain);
      _du.insert(changeDelta, '\n');
      return changeDelta;
    }

    final nextNewLine = getNextNewLine(currItr);
    final attributes = nextNewLine.operation?.attributes;

    _du.insert(changeDelta, '\n', attributes);

    return changeDelta;
  }
}
