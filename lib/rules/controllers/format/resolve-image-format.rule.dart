import '../../../delta/models/delta.model.dart';
import '../../../documents/models/attribute.model.dart';
import '../../models/format-rule.model.dart';

// Produces Delta with attributes applied to image leaf node
class ResolveImageFormatRule extends FormatRuleM {
  const ResolveImageFormatRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    if (attribute == null || attribute.key != AttributeM.style.key) {
      return null;
    }

    assert(len == 1 && data == null);

    final delta = DeltaM()
      ..retain(index)
      ..retain(1, attribute.toJson());

    return delta;
  }
}
