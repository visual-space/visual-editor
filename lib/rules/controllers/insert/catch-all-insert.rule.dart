import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/delta/delta.model.dart';
import '../../../document/services/delta.utils.dart';
import '../../models/insert-rule.model.dart';

// Fallback rule which simply inserts text as-is without any special handling.
class CatchAllInsertRule extends InsertRuleM {
  final _du = DeltaUtils();

  CatchAllInsertRule();

  @override
  DeltaM applyRule(
    DeltaM docDelta,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
    String plainText = '',
  }) {
    final changeDelta = DeltaM();

    _du.retain(changeDelta, index + (len ?? 0));
    _du.insert(changeDelta, data);

    return changeDelta;
  }
}
