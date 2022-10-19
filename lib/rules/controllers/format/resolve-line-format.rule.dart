import '../../../documents/controllers/delta.iterator.dart';
import '../../../documents/models/attribute-scope.enum.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/attributes/attributes-types.model.dart';
import '../../../documents/models/delta/delta.model.dart';
import '../../../documents/models/delta/operation.model.dart';
import '../../models/format-rule.model.dart';

// Produces Delta with line-level attributes applied strictly to newline characters.
class ResolveLineFormatRule extends FormatRuleM {
  const ResolveLineFormatRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    if (attribute!.scope != AttributeScope.BLOCK) {
      return null;
    }

    // Apply line styles to all newline characters within range of this retain operation.
    var result = DeltaM()..retain(index);
    final itr = DeltaIterator(document)..skip(index);
    OperationM op;

    for (var cur = 0; cur < len! && itr.hasNext; cur += op.length!) {
      op = itr.next(len - cur);
      final opText = op.data is String ? op.data as String : '';

      if (!opText.contains('\n')) {
        result.retain(op.length!);
        continue;
      }

      final delta = _applyAttribute(opText, op, attribute);
      result = result.concat(delta);
    }

    // And include extra newline after retain
    while (itr.hasNext) {
      op = itr.next();
      final opText = op.data is String ? op.data as String : '';
      final lf = opText.indexOf('\n');

      if (lf < 0) {
        result.retain(op.length!);
        continue;
      }

      final delta = _applyAttribute(opText, op, attribute, firstOnly: true);
      result = result.concat(delta);
      break;
    }

    return result;
  }

  DeltaM _applyAttribute(
    String text,
    OperationM op,
    AttributeM attribute, {
    bool firstOnly = false,
  }) {
    final result = DeltaM();
    var offset = 0;
    var lf = text.indexOf('\n');
    final removedBlocks = _getRemovedBlocks(attribute, op);

    while (lf >= 0) {
      final actualStyle = attribute.toJson()..addEntries(removedBlocks);
      result
        ..retain(lf - offset)
        ..retain(1, actualStyle);

      if (firstOnly) {
        return result;
      }

      offset = lf + 1;
      lf = text.indexOf('\n', offset);
    }
    // Retain any remaining characters in text
    result.retain(text.length - offset);

    return result;
  }

  Iterable<MapEntry<String, dynamic>> _getRemovedBlocks(
    AttributeM<dynamic> attribute,
    OperationM op,
  ) {
    // Enforce Block Format exclusivity by rule
    if (!AttributesTypesM.exclusiveBlockKeys.contains(attribute.key)) {
      return <MapEntry<String, dynamic>>[];
    }

    return op.attributes?.keys
            .where((key) =>
                AttributesTypesM.exclusiveBlockKeys.contains(key) &&
                attribute.key != key &&
                attribute.value != null)
            .map((key) => MapEntry<String, dynamic>(key, null)) ??
        [];
  }
}
