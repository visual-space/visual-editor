import '../../../delta/controllers/delta-iterator.controller.dart';
import '../../../delta/models/delta.model.dart';
import '../../../documents/models/attribute.model.dart';
import '../../models/delete-rule.model.dart';

// Preserves line format when user deletes the line's newline character effectively merging it with the next line.
// This rule makes sure to apply all style attributes of deleted newline to the next available newline,
// which may reset any style attributes already present there.
class PreserveLineStyleOnMergeRule extends DeleteRuleM {
  const PreserveLineStyleOnMergeRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    final itr = DeltaIterator(document)..skip(index);
    var op = itr.next(1);

    if (op.data != '\n') {
      return null;
    }

    final isNotPlain = op.isNotPlain;
    final attrs = op.attributes;

    itr.skip(len! - 1);

    if (!itr.hasNext) {
      // User attempts to delete the last newline character, prevent it.
      return DeltaM()
        ..retain(index)
        ..delete(len - 1);
    }

    final delta = DeltaM()
      ..retain(index)
      ..delete(len);

    while (itr.hasNext) {
      op = itr.next();
      final text = op.data is String ? (op.data as String?)! : '';
      final lineBreak = text.indexOf('\n');

      if (lineBreak == -1) {
        delta.retain(op.length!);
        continue;
      }

      var attributes = op.attributes == null
          ? null
          : op.attributes!.map<String, dynamic>(
              (key, dynamic value) => MapEntry<String, dynamic>(key, null));

      if (isNotPlain) {
        attributes ??= <String, dynamic>{};
        attributes.addAll(attrs!);
      }
      delta
        ..retain(lineBreak)
        ..retain(1, attributes);
      break;
    }

    return delta;
  }
}
