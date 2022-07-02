import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/delta/delta.model.dart';
import '../../models/insert-rule.model.dart';

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
