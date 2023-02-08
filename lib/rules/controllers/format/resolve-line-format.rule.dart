import '../../../document/controllers/delta.iterator.dart';
import '../../../document/models/attributes/attribute-scope.enum.dart';
import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/attributes/attributes-types.model.dart';
import '../../../document/models/delta/delta.model.dart';
import '../../../document/models/delta/operation.model.dart';
import '../../../document/services/delta.utils.dart';
import '../../models/format-rule.model.dart';

// Produces Delta with line-level attributes applied strictly to newline characters.
class ResolveLineFormatRule extends FormatRuleM {
  final _du = DeltaUtils();

  ResolveLineFormatRule();

  @override
  DeltaM? applyRule(
    DeltaM docDelta,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
    String plainText = '',
  }) {
    if (attribute!.scope != AttributeScope.BLOCK) {
      return null;
    }

    // Apply line styles to all newline characters within range of this retain operation.
    var changeDelta = DeltaM();

    _du.retain(changeDelta, index);

    final currItr = DeltaIterator(docDelta)..skip(index);
    OperationM operation;

    for (var cur = 0; cur < len! && currItr.hasNext; cur += operation.length!) {
      operation = currItr.next(len - cur);
      final opText = operation.data is String ? operation.data as String : '';

      if (!opText.contains('\n')) {
        _du.retain(changeDelta, operation.length!);

        continue;
      }

      final attrDelta = _applyAttribute(opText, operation, attribute);
      changeDelta = _du.concat(changeDelta, attrDelta);
    }

    // And include extra newline after retain
    while (currItr.hasNext) {
      operation = currItr.next();
      final opText = operation.data is String ? operation.data as String : '';
      final lf = opText.indexOf('\n');

      if (lf < 0) {
        _du.retain(changeDelta, operation.length!);

        continue;
      }

      final attrDelta = _applyAttribute(
        opText,
        operation,
        attribute,
        firstOnly: true,
      );
      changeDelta = _du.concat(changeDelta, attrDelta);

      break;
    }

    return changeDelta;
  }

  DeltaM _applyAttribute(
    String text,
    OperationM op,
    AttributeM attribute, {
    bool firstOnly = false,
  }) {
    final changeDelta = DeltaM();
    var offset = 0;
    var lf = text.indexOf('\n');
    final removedBlocks = _getRemovedBlocks(attribute, op);

    while (lf >= 0) {
      final actualStyle = attribute.toJson()..addEntries(removedBlocks);

      _du.retain(changeDelta, lf - offset);
      _du.retain(changeDelta, 1, actualStyle);

      if (firstOnly) {
        return changeDelta;
      }

      offset = lf + 1;
      lf = text.indexOf('\n', offset);
    }

    // Retain any remaining characters in text
    _du.retain(changeDelta, text.length - offset);

    return changeDelta;
  }

  Iterable<MapEntry<String, dynamic>> _getRemovedBlocks(
    AttributeM<dynamic> attribute,
    OperationM operation,
  ) {
    // Enforce Block Format exclusivity by rule
    if (!AttributesTypesM.exclusiveBlockKeys.contains(attribute.key)) {
      return <MapEntry<String, dynamic>>[];
    }

    return operation.attributes?.keys
            .where((key) =>
                AttributesTypesM.exclusiveBlockKeys.contains(key) &&
                attribute.key != key &&
                attribute.value != null)
            .map((key) => MapEntry<String, dynamic>(key, null)) ??
        [];
  }
}
