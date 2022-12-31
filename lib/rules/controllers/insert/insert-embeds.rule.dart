import '../../../documents/controllers/delta.iterator.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/delta/delta.model.dart';
import '../../../embeds/const/embeds.const.dart';
import '../../models/insert-rule.model.dart';

// Handles all format operations which manipulate embeds.
// This rule wraps line breaks around video, not image.
class InsertEmbedsRule extends InsertRuleM {
  const InsertEmbedsRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    if (data is String) {
      return null;
    }

    assert(data is Map);

    if (!(data as Map).containsKey(VIDEO_EMBED_TYPE)) {
      return null;
    }

    final delta = DeltaM()..retain(index + (len ?? 0));
    final itr = DeltaIterator(document);
    final prev = itr.skip(index), cur = itr.next();
    final textBefore = prev?.data is String ? prev!.data as String? : '';
    final textAfter = cur.data is String ? (cur.data as String?)! : '';
    final isNewlineBefore = prev == null || textBefore!.endsWith('\n');
    final isNewlineAfter = textAfter.startsWith('\n');

    if (isNewlineBefore && isNewlineAfter) {
      return delta..insert(data);
    }

    Map<String, dynamic>? lineStyle;

    if (textAfter.contains('\n')) {
      lineStyle = cur.attributes;
    } else {
      while (itr.hasNext) {
        final op = itr.next();
        if ((op.data is String ? op.data as String? : '')!.contains('\n')) {
          lineStyle = op.attributes;
          break;
        }
      }
    }

    if (!isNewlineBefore) {
      delta.insert('\n', lineStyle);
    }

    delta.insert(data);

    if (!isNewlineAfter) {
      delta.insert('\n');
    }

    return delta;
  }
}
