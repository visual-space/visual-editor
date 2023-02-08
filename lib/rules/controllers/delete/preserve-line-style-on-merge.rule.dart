import '../../../document/controllers/delta.iterator.dart';
import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/delta/delta.model.dart';
import '../../../document/services/delta.utils.dart';
import '../../models/delete-rule.model.dart';

// Preserves line format when user deletes the line's newline character effectively merging it with the next line.
// This rule makes sure to apply all style attributes of deleted newline to the next available newline,
// which may reset any style attributes already present there.
class PreserveLineStyleOnMergeRule extends DeleteRuleM {
  final _du = DeltaUtils();

  PreserveLineStyleOnMergeRule();

  @override
  DeltaM? applyRule(
    DeltaM docDelta,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
    String plainText = '',
  }) {
    final currItr = DeltaIterator(docDelta)..skip(index);
    var operation = currItr.next(1);

    if (operation.data != '\n') {
      return null;
    }

    final isNotPlain = operation.isNotPlain;
    final attrs = operation.attributes;

    currItr.skip(len! - 1);

    if (!currItr.hasNext) {
      // User attempts to delete the last newline character, prevent it.
      final deltaRes = DeltaM();

      _du.retain(deltaRes, index);
      _du.delete(deltaRes, len - 1);

      return deltaRes;
    }

    final changeDelta = DeltaM();
    _du.retain(changeDelta, index);
    _du.delete(changeDelta, len);

    while (currItr.hasNext) {
      operation = currItr.next();
      final text = operation.data is String ? (operation.data as String?)! : '';
      final lineBreak = text.indexOf('\n');

      if (lineBreak == -1) {
        _du.retain(changeDelta, operation.length!);
        continue;
      }

      var attributes = operation.attributes == null
          ? null
          : operation.attributes!.map<String, dynamic>(
              (key, dynamic value) => MapEntry<String, dynamic>(key, null),
            );

      if (isNotPlain) {
        attributes ??= <String, dynamic>{};
        attributes.addAll(attrs!);
      }

      _du.retain(changeDelta, lineBreak);
      _du.retain(changeDelta, 1, attributes);

      break;
    }

    return changeDelta;
  }
}
