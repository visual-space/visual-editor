import '../../../delta/controllers/delta-iterator.controller.dart';
import '../../../delta/models/delta.model.dart';
import '../../../documents/models/attribute.model.dart';
import '../../models/format-rule.model.dart';

// Allows updating link format with collapsed selection.
class FormatLinkAtCaretPositionRule extends FormatRuleM {
  const FormatLinkAtCaretPositionRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    if (attribute!.key != AttributeM.link.key || len! > 0) {
      return null;
    }

    final delta = DeltaM();
    final itr = DeltaIterator(document);
    final before = itr.skip(index), after = itr.next();
    int? beg = index, retain = 0;

    if (before != null && before.hasAttribute(attribute.key)) {
      beg -= before.length!;
      retain = before.length;
    }

    if (after.hasAttribute(attribute.key)) {
      if (retain != null) retain += after.length!;
    }

    if (retain == 0) {
      return null;
    }

    delta
      ..retain(beg)
      ..retain(retain!, attribute.toJson());

    return delta;
  }
}
