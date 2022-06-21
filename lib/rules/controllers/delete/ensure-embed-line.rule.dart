import '../../../delta/controllers/delta-iterator.controller.dart';
import '../../../delta/models/delta.model.dart';
import '../../../documents/models/attribute.model.dart';
import '../../models/delete-rule.model.dart';

// Prevents user from merging a line containing an embed with other lines.
class EnsureEmbedLineRule extends DeleteRuleM {
  const EnsureEmbedLineRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    final itr = DeltaIterator(document);
    var op = itr.skip(index);
    int? indexDelta = 0, lengthDelta = 0, remain = len;
    var embedFound = op != null && op.data is! String;
    final hasLineBreakBefore =
        !embedFound && (op == null || (op.data as String).endsWith('\n'));

    if (embedFound) {
      var candidate = itr.next(1);

      if (remain != null) {
        remain--;

        if (candidate.data == '\n') {
          indexDelta++;
          lengthDelta--;

          candidate = itr.next(1);
          remain--;
          if (candidate.data == '\n') {
            lengthDelta++;
          }
        }
      }
    }

    op = itr.skip(remain!);

    if (op != null &&
        (op.data is String ? op.data as String? : '')!.endsWith('\n')) {
      final candidate = itr.next(1);

      if (candidate.data is! String && !hasLineBreakBefore) {
        embedFound = true;
        lengthDelta--;
      }
    }

    if (!embedFound) {
      return null;
    }

    return DeltaM()
      ..retain(index + indexDelta)
      ..delete(len! + lengthDelta);
  }
}
