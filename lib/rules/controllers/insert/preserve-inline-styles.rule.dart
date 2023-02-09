import '../../../document/controllers/delta.iterator.dart';
import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/attributes/attributes.model.dart';
import '../../../document/models/delta/delta.model.dart';
import '../../../document/services/delta.utils.dart';
import '../../models/insert-rule.model.dart';

// TODO Improve comments.
// Preserves inline styles when user inserts text inside formatted segment.
class PreserveInlineStylesRule extends InsertRuleM {
  final _du = DeltaUtils();

  PreserveInlineStylesRule();

  @override
  DeltaM? applyRule(
    DeltaM docDelta,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
    String plainText = '',
  }) {
    if (data is! String || data.contains('\n')) {
      return null;
    }

    final currItr = DeltaIterator(docDelta);
    final prev = currItr.skip(index);

    if (prev == null ||
        prev.data is! String ||
        (prev.data as String).contains('\n')) {
      return null;
    }

    final attributes = prev.attributes;
    final text = data;

    if (attributes == null || !attributes.containsKey(AttributesM.link.key)) {
      final deltaRes = DeltaM();

      _du.retain(deltaRes, index + (len ?? 0));
      _du.insert(deltaRes, text, attributes);

      return deltaRes;
    }

    final next = currItr.next();
    final nextAttributes = next.attributes ?? const <String, dynamic>{};

    final currAndNextNodesAreLinks = attributes[AttributesM.link.key] ==
        nextAttributes[AttributesM.link.key];

    // We want to keep link styling for each char typed inside a word that is marked as a link.
    if (currAndNextNodesAreLinks) {
      final _deltaRes = DeltaM();

      _du.retain(_deltaRes, index + (len ?? 0));
      _du.insert(_deltaRes, text, attributes);

      return _deltaRes;
    }

    attributes.remove(AttributesM.link.key);

    final changeDelta = DeltaM();

    _du.retain(changeDelta, index + (len ?? 0));
    _du.insert(changeDelta, text, attributes.isEmpty ? null : attributes);

    return changeDelta;
  }
}
