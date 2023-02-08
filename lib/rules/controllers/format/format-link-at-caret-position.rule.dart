import '../../../document/controllers/delta.iterator.dart';
import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/attributes/attributes.model.dart';
import '../../../document/models/delta/delta.model.dart';
import '../../../document/services/delta.utils.dart';
import '../../models/format-rule.model.dart';

// Allows updating link format with collapsed selection.
class FormatLinkAtCaretPositionRule extends FormatRuleM {
  final _du = DeltaUtils();

  FormatLinkAtCaretPositionRule();

  @override
  DeltaM? applyRule(
    DeltaM docDelta,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
    String plainText = '',
  }) {
    if (attribute!.key != AttributesM.link.key || len! > 0) {
      return null;
    }

    final changeDelta = DeltaM();
    final currItr = DeltaIterator(docDelta);
    final before = currItr.skip(index), after = currItr.next();
    int? beg = index, retain = 0;

    if (before != null && before.hasAttribute(attribute.key)) {
      beg -= before.length!;
      retain = before.length;
    }

    if (after.hasAttribute(attribute.key)) {
      if (retain != null) {
        retain += after.length!;
      }
    }

    if (retain == 0) {
      return null;
    }

    _du.retain(changeDelta, beg);
    _du.retain(changeDelta, retain!, attribute.toJson());

    return changeDelta;
  }
}
