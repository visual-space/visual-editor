import '../../../document/controllers/delta.iterator.dart';
import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/attributes/attributes.model.dart';
import '../../../document/models/delta/delta.model.dart';
import '../../../document/services/delta.utils.dart';
import '../../models/insert-rule.model.dart';

// Resets format for a newly inserted line when insert occurred at the end of a line (right before a newline).
// This handles scenarios when a new line is added when at the end of a heading line.
// The newly added line should be a regular paragraph.
class ResetLineFormatOnNewLineRule extends InsertRuleM {
  final _du = DeltaUtils();

  ResetLineFormatOnNewLineRule();

  @override
  DeltaM? applyRule(
    DeltaM delta,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
    String plainText = '',
  }) {
    if (data is! String || data != '\n') {
      return null;
    }

    final currItr = DeltaIterator(delta)..skip(index);
    final currOp = currItr.next();

    if (currOp.data is! String || !(currOp.data as String).startsWith('\n')) {
      return null;
    }

    Map<String, dynamic>? resetStyle;

    if (currOp.attributes != null &&
        currOp.attributes!.containsKey(AttributesM.header.key)) {
      resetStyle = AttributesM.header.toJson();
    }

    final changeDelta = DeltaM();

    _du.retain(changeDelta, index + (len ?? 0));
    _du.insert(changeDelta, '\n', currOp.attributes);
    _du.retain(changeDelta, 1, resetStyle);
    _du.trim(changeDelta);

    return changeDelta;
  }
}
