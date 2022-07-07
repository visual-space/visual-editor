import '../../../documents/controllers/delta.iterator.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/attributes/attributes.model.dart';
import '../../../documents/models/attributes/styling-attributes.dart';
import '../../../documents/models/delta/delta.model.dart';
import '../../models/insert-rule.model.dart';

// Applies link format to text segment (which looks like a link) when user inserts space character after it.
class AutoFormatLinksRule extends InsertRuleM {
  const AutoFormatLinksRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    if (data is! String || data != ' ') {
      return null;
    }

    final itr = DeltaIterator(document);
    final prev = itr.skip(index);

    if (prev == null || prev.data is! String) {
      return null;
    }

    try {
      final cand = (prev.data as String).split('\n').last.split(' ').last;
      final link = Uri.parse(cand);

      if (!['https', 'http'].contains(link.scheme)) {
        return null;
      }

      final attributes = prev.attributes ?? <String, dynamic>{};

      if (attributes.containsKey(AttributesM.link.key)) {
        return null;
      }

      attributes.addAll(LinkAttributeM(link.toString()).toJson());

      return DeltaM()
        ..retain(index + (len ?? 0) - cand.length)
        ..retain(cand.length, attributes)
        ..insert(data, prev.attributes);
    } on FormatException {
      return null;
    }
  }
}
