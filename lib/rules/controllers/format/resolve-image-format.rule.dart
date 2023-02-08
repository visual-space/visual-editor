import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/attributes/attributes.model.dart';
import '../../../document/models/delta/delta.model.dart';
import '../../../document/services/delta.utils.dart';
import '../../models/format-rule.model.dart';

// Produces Delta with attributes applied to image leaf node
class ResolveImageFormatRule extends FormatRuleM {
  final _du = DeltaUtils();

  ResolveImageFormatRule();

  @override
  DeltaM? applyRule(
    DeltaM docDelta,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
    String plainText = '',
  }) {
    if (attribute == null || attribute.key != AttributesM.style.key) {
      return null;
    }

    assert(len == 1 && data == null);

    final changeDelta = DeltaM();

    _du.retain(changeDelta, index);
    _du.retain(changeDelta, 1, attribute.toJson());

    return changeDelta;
  }
}
