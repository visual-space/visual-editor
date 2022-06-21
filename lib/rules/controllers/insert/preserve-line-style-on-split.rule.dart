import '../../../delta/controllers/delta-iterator.controller.dart';
import '../../../delta/models/delta.model.dart';
import '../../../documents/models/attribute.model.dart';
import '../../models/insert-rule.model.dart';
import '../../models/rules.utils.dart';

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

    final nextNewLine = getNextNewLine(itr);
    final attributes = nextNewLine.item1?.attributes;

    return delta..insert('\n', attributes);
  }
}
