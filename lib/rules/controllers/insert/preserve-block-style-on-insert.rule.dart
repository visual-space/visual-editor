import '../../../document/controllers/delta.iterator.dart';
import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/attributes/attributes.model.dart';
import '../../../document/models/delta/delta.model.dart';
import '../../../document/services/delta.utils.dart';
import '../../../document/services/nodes/styles.utils.dart';
import '../../models/insert-rule.model.dart';
import '../../models/rules.utils.dart';

final _stylesUtils = StylesUtils();

// Preserves block style when user inserts text containing newlines.
// This rule handles:
//   * inserting a new line in a block
//   * pasting text containing multiple lines of text in a block
// This rule may also be activated for changes triggered by auto-correct.
class PreserveBlockStyleOnInsertRule extends InsertRuleM {
  final _du = DeltaUtils();

  PreserveBlockStyleOnInsertRule();

  @override
  DeltaM? applyRule(
    DeltaM docDelta,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
    String plainText = '',
  }) {
    if (data is! String || !data.contains('\n')) {
      // Only interested in text containing at least one newline character.
      return null;
    }

    final currItr = DeltaIterator(docDelta)..skip(index);

    // Look for the next newline.
    final nextNewLine = getNextNewLine(currItr);
    final lineStyle = _stylesUtils.fromJson(
      nextNewLine.operation?.attributes ?? <String, dynamic>{},
    );
    final blockStyle = _stylesUtils.getBlocksExceptHeader(lineStyle);

    // Are we currently in a block? If not then ignore.
    if (blockStyle.isEmpty) {
      return null;
    }

    final resetStyle = <String, dynamic>{};

    // If current line had heading style applied to it we'll need to move this style to
    // the newly inserted line before it and reset style of the original line.
    if (lineStyle.containsKey(AttributesM.header.key)) {
      resetStyle.addAll(
        AttributesM.header.toJson(),
      );
    }

    // Go over each inserted line and ensure block style is applied.
    final lines = data.split('\n');
    final changeDelta = DeltaM();
    _du.retain(changeDelta, index + (len ?? 0));

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.isNotEmpty) {
        _du.insert(changeDelta, line);
      }

      if (i == 0) {
        // The first line should inherit the lineStyle entirely.
        _du.insert(changeDelta, '\n', lineStyle.toJson());
      } else if (i < lines.length - 1) {
        // We don't want to insert a newline after the last chunk of text, so -1
        final blockAttributes = blockStyle.isEmpty
            ? null
            : blockStyle.map<String, dynamic>(
                (_, attribute) =>
                    MapEntry<String, dynamic>(attribute.key, attribute.value),
              );
        _du.insert(changeDelta, '\n', blockAttributes);
      }
    }

    // Reset style of the original newline character if needed.
    if (resetStyle.isNotEmpty) {
      _du.retain(changeDelta, nextNewLine.offset!);
      _du.retain(
        changeDelta,
        (nextNewLine.operation!.data as String).indexOf('\n'),
      );
      _du.retain(changeDelta, 1, resetStyle);
    }

    return changeDelta;
  }
}
