import '../../../delta/controllers/delta-iterator.controller.dart';
import '../../../delta/models/delta.model.dart';
import '../../../delta/models/operation.model.dart';
import '../../../documents/models/attribute-scope.enum.dart';
import '../../../documents/models/attribute.model.dart';
import '../../models/format-rule.model.dart';

// Produces Delta with inline-level attributes applied to all characters except newlines.
class ResolveInlineFormatRule extends FormatRuleM {
  const ResolveInlineFormatRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    if (attribute!.scope != AttributeScope.INLINE) {
      return null;
    }

    final delta = DeltaM()..retain(index);
    final itr = DeltaIterator(document)..skip(index);
    Operation op;

    for (var cur = 0; cur < len! && itr.hasNext; cur += op.length!) {
      op = itr.next(len - cur);
      final text = op.data is String ? (op.data as String?)! : '';
      var lineBreak = text.indexOf('\n');

      if (lineBreak < 0) {
        delta.retain(op.length!, attribute.toJson());
        continue;
      }

      var pos = 0;

      while (lineBreak >= 0) {
        delta
          ..retain(lineBreak - pos, attribute.toJson())
          ..retain(1);
        pos = lineBreak + 1;
        lineBreak = text.indexOf('\n', pos);
      }

      if (pos < op.length!) {
        delta.retain(op.length! - pos, attribute.toJson());
      }
    }

    return delta;
  }
}