import '../../../documents/controllers/delta.iterator.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/delta/delta.model.dart';
import '../../models/delete-rule.model.dart';

// Fallback rule for delete operations which simply deletes specified text
// range without any special handling.
class CatchAllDeleteRule extends DeleteRuleM {
  const CatchAllDeleteRule();

  @override
  DeltaM applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    final itr = DeltaIterator(document)..skip(index + len!);

    return DeltaM()
      ..retain(index)
      ..delete(itr.hasNext ? len : len - 1);
  }
}
