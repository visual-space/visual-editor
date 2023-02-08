import '../../../document/controllers/delta.iterator.dart';
import '../../../document/models/attributes/attribute-scope.enum.dart';
import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/delta/delta.model.dart';
import '../../../document/models/delta/operation.model.dart';
import '../../../document/services/delta.utils.dart';
import '../../models/format-rule.model.dart';

// Produces Delta with inline-level attributes applied to all characters except newlines.
class ResolveInlineFormatRule extends FormatRuleM {
  final _du = DeltaUtils();

  ResolveInlineFormatRule();

  @override
  DeltaM? applyRule(
    DeltaM docDelta,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
    String plainText = '',
  }) {
    if (attribute!.scope != AttributeScope.INLINE) {
      return null;
    }

    final changeDelta = DeltaM();

    _du.retain(changeDelta, index);

    final currItr = DeltaIterator(docDelta)..skip(index);
    OperationM operation;

    for (var cur = 0; cur < len! && currItr.hasNext; cur += operation.length!) {
      operation = currItr.next(len - cur);
      final text = operation.data is String ? (operation.data as String?)! : '';
      var lineBreak = text.indexOf('\n');

      if (lineBreak < 0) {
        _du.retain(changeDelta, operation.length!, attribute.toJson());

        continue;
      }

      var pos = 0;

      while (lineBreak >= 0) {
        _du.retain(changeDelta, lineBreak - pos, attribute.toJson());
        _du.retain(changeDelta, 1);
        pos = lineBreak + 1;
        lineBreak = text.indexOf('\n', pos);
      }

      if (pos < operation.length!) {
        _du.retain(changeDelta, operation.length! - pos, attribute.toJson());
      }
    }

    return changeDelta;
  }
}
