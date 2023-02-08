import '../../../document/controllers/delta.iterator.dart';
import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/attributes/attributes.model.dart';
import '../../../document/models/attributes/styling-attributes.dart';
import '../../../document/models/delta/delta.model.dart';
import '../../../document/services/delta.utils.dart';
import '../../models/insert-rule.model.dart';

// Applies link format to text segment (which looks like a link) when user inserts space character after it.
class AutoFormatLinksRule extends InsertRuleM {
  final _du = DeltaUtils();

  AutoFormatLinksRule();

  @override
  DeltaM? applyRule(
    DeltaM docDelta,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
    String plainText = '',
  }) {
    if (data is! String || data != ' ') {
      return null;
    }

    final currItr = DeltaIterator(docDelta);
    final prev = currItr.skip(index);

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

      final changeDelta = DeltaM();

      _du.retain(changeDelta, index + (len ?? 0) - cand.length);
      _du.retain(changeDelta, cand.length, attributes);
      _du.insert(changeDelta, data, prev.attributes);

      return changeDelta;
    } on FormatException {
      return null;
    }
  }
}
