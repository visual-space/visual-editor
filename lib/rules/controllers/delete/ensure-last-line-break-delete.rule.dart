import '../../../document/controllers/delta.iterator.dart';
import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/delta/delta.model.dart';
import '../../../document/services/delta.utils.dart';
import '../../models/delete-rule.model.dart';

class EnsureLastLineBreakDeleteRule extends DeleteRuleM {
  final _du = DeltaUtils();

  EnsureLastLineBreakDeleteRule();

  @override
  DeltaM? applyRule(
    DeltaM docDelta,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
    String plainText = '',
  }) {
    final currItr = DeltaIterator(docDelta)..skip(index + len!);

    final changeDelta = DeltaM();

    _du.retain(changeDelta, index);
    _du.delete(changeDelta, currItr.hasNext ? len : len - 1);

    return changeDelta;
  }
}
