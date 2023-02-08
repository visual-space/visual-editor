import '../../../document/controllers/delta.iterator.dart';
import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/delta/delta.model.dart';
import '../../../document/services/delta.utils.dart';
import '../../../embeds/const/embeds.const.dart';
import '../../models/insert-rule.model.dart';

// Handles all format operations which manipulate embeds.
// This rule wraps line breaks around video, not image.
class InsertEmbedsRule extends InsertRuleM {
  final _du = DeltaUtils();

  InsertEmbedsRule();

  @override
  DeltaM? applyRule(
    DeltaM docDelta,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
    String plainText = '',
  }) {
    if (data is String) {
      return null;
    }

    assert(data is Map);

    if (!(data as Map).containsKey(VIDEO_EMBED_TYPE)) {
      return null;
    }

    final changeDelta = DeltaM();

    _du.retain(changeDelta, index + (len ?? 0));

    final currItr = DeltaIterator(docDelta);
    final prev = currItr.skip(index), cur = currItr.next();
    final textBefore = prev?.data is String ? prev!.data as String? : '';
    final textAfter = cur.data is String ? (cur.data as String?)! : '';
    final isNewlineBefore = prev == null || textBefore!.endsWith('\n');
    final isNewlineAfter = textAfter.startsWith('\n');

    if (isNewlineBefore && isNewlineAfter) {
      _du.insert(changeDelta, data);
      return changeDelta;
    }

    Map<String, dynamic>? lineStyle;

    if (textAfter.contains('\n')) {
      lineStyle = cur.attributes;
    } else {
      while (currItr.hasNext) {
        final operation = currItr.next();

        if ((operation.data is String ? operation.data as String? : '')!
            .contains('\n')) {
          lineStyle = operation.attributes;
          break;
        }
      }
    }

    if (!isNewlineBefore) {
      _du.insert(changeDelta, '\n', lineStyle);
    }

    _du.insert(changeDelta, data);

    if (!isNewlineAfter) {
      _du.insert(changeDelta, '\n');
    }

    return changeDelta;
  }
}
