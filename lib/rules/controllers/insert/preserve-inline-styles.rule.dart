import '../../../documents/controllers/delta.iterator.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/delta/delta.model.dart';
import '../../models/insert-rule.model.dart';

// Preserves inline styles when user inserts text inside formatted segment.
class PreserveInlineStylesRule extends InsertRuleM {
  const PreserveInlineStylesRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    if (data is! String || data.contains('\n')) {
      return null;
    }

    final itr = DeltaIterator(document);
    final prev = itr.skip(index);

    if (prev == null ||
        prev.data is! String ||
        (prev.data as String).contains('\n')) {
      return null;
    }

    final attributes = prev.attributes;
    final text = data;

    if (attributes == null || !attributes.containsKey(AttributeM.link.key)) {
      return DeltaM()
        ..retain(index + (len ?? 0))
        ..insert(text, attributes);
    }

    attributes.remove(AttributeM.link.key);
    final delta = DeltaM()
      ..retain(index + (len ?? 0))
      ..insert(text, attributes.isEmpty ? null : attributes);
    final next = itr.next();
    final nextAttributes = next.attributes ?? const <String, dynamic>{};

    if (!nextAttributes.containsKey(AttributeM.link.key)) {
      return delta;
    }

    if (attributes[AttributeM.link.key] ==
        nextAttributes[AttributeM.link.key]) {
      return DeltaM()
        ..retain(index + (len ?? 0))
        ..insert(text, attributes);
    }

    return delta;
  }
}
