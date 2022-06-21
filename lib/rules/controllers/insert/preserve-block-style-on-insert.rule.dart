import '../../../delta/controllers/delta-iterator.controller.dart';
import '../../../delta/models/delta.model.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/style.model.dart';
import '../../models/insert-rule.model.dart';
import '../../models/rules.utils.dart';

// Preserves block style when user inserts text containing newlines.
// This rule handles:
//   * inserting a new line in a block
//   * pasting text containing multiple lines of text in a block
// This rule may also be activated for changes triggered by auto-correct.
class PreserveBlockStyleOnInsertRule extends InsertRuleM {
  const PreserveBlockStyleOnInsertRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    if (data is! String || !data.contains('\n')) {
      // Only interested in text containing at least one newline character.
      return null;
    }

    final itr = DeltaIterator(document)..skip(index);

    // Look for the next newline.
    final nextNewLine = getNextNewLine(itr);
    final lineStyle = StyleM.fromJson(
      nextNewLine.item1?.attributes ?? <String, dynamic>{},
    );
    final blockStyle = lineStyle.getBlocksExceptHeader();

    // Are we currently in a block? If not then ignore.
    if (blockStyle.isEmpty) {
      return null;
    }

    final resetStyle = <String, dynamic>{};

    // If current line had heading style applied to it we'll need to move this style to
    // the newly inserted line before it and reset style of the original line.
    if (lineStyle.containsKey(AttributeM.header.key)) {
      resetStyle.addAll(
        AttributeM.header.toJson(),
      );
    }

    // Go over each inserted line and ensure block style is applied.
    final lines = data.split('\n');
    final delta = DeltaM()..retain(index + (len ?? 0));

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.isNotEmpty) {
        delta.insert(line);
      }

      if (i == 0) {
        // The first line should inherit the lineStyle entirely.
        delta.insert('\n', lineStyle.toJson());
      } else if (i < lines.length - 1) {
        // We don't want to insert a newline after the last chunk of text, so -1
        final blockAttributes = blockStyle.isEmpty
            ? null
            : blockStyle.map<String, dynamic>(
                (_, attribute) =>
                    MapEntry<String, dynamic>(attribute.key, attribute.value),
              );
        delta.insert('\n', blockAttributes);
      }
    }

    // Reset style of the original newline character if needed.
    if (resetStyle.isNotEmpty) {
      delta
        ..retain(nextNewLine.item2!)
        ..retain((nextNewLine.item1!.data as String).indexOf('\n'))
        ..retain(1, resetStyle);
    }

    return delta;
  }
}
