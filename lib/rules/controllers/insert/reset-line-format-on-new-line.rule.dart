import '../../../documents/controllers/delta.iterator.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/delta/delta.model.dart';
import '../../models/insert-rule.model.dart';

// Resets format for a newly inserted line when insert occurred at the end of a line (right before a newline).
// This handles scenarios when a new line is added when at the end of a heading line.
// The newly added line should be a regular paragraph.
class ResetLineFormatOnNewLineRule extends InsertRuleM {
  const ResetLineFormatOnNewLineRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    if (data is! String || data != '\n') {
      return null;
    }

    final itr = DeltaIterator(document)..skip(index);
    final cur = itr.next();

    if (cur.data is! String || !(cur.data as String).startsWith('\n')) {
      return null;
    }

    Map<String, dynamic>? resetStyle;

    if (cur.attributes != null &&
        cur.attributes!.containsKey(AttributeM.header.key)) {
      resetStyle = AttributeM.header.toJson();
    }

    return DeltaM()
      ..retain(index + (len ?? 0))
      ..insert('\n', cur.attributes)
      ..retain(1, resetStyle)
      ..trim();
  }
}
