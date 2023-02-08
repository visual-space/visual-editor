import '../../../document/controllers/delta.iterator.dart';
import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/delta/delta.model.dart';
import '../../../document/services/delta.utils.dart';
import '../../models/delete-rule.model.dart';

// Prevents user from merging a line containing an embed with other lines.
class EnsureEmbedLineRule extends DeleteRuleM {
  final _du = DeltaUtils();

  EnsureEmbedLineRule();

  @override
  DeltaM? applyRule(
    DeltaM docDelta,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
    String plainText = '',
  }) {
    final currItr = DeltaIterator(docDelta);
    var operation = currItr.skip(index);
    int? indexDelta = 0, lengthDelta = 0, remain = len;
    var embedFound = operation != null && operation.data is! String;
    final hasLineBreakBefore = !embedFound &&
        (operation == null || (operation.data as String).endsWith('\n'));

    if (embedFound) {
      var candidate = currItr.next(1);

      if (remain != null) {
        remain--;

        if (candidate.data == '\n') {
          indexDelta++;
          lengthDelta--;

          candidate = currItr.next(1);
          remain--;

          if (candidate.data == '\n') {
            lengthDelta++;
          }
        }
      }
    }

    operation = currItr.skip(remain!);

    // TODO Alias
    if (operation != null &&
        (operation.data is String ? operation.data as String? : '')!
            .endsWith('\n')) {
      final candidate = currItr.next(1);

      if (candidate.data is! String && !hasLineBreakBefore) {
        embedFound = true;
        lengthDelta--;
      }
    }

    if (!embedFound) {
      return null;
    }

    final changeDelta = DeltaM();

    _du.retain(changeDelta, index + indexDelta);
    _du.delete(changeDelta, len! + lengthDelta);

    return changeDelta;
  }
}
