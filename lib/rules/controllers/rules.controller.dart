import '../../../document/models/document.model.dart';
import '../../../rules/models/rule-type.enum.dart';
import '../../document/models/attributes/attribute.model.dart';
import '../../document/models/delta/delta.model.dart';
import '../../document/services/delta.utils.dart';
import '../models/rule.model.dart';
import 'delete/catch-all-delete.rule.dart';
import 'delete/ensure-embed-line.rule.dart';
import 'delete/ensure-last-line-break-delete.rule.dart';
import 'delete/preserve-line-style-on-merge.rule.dart';
import 'format/format-link-at-caret-position.rule.dart';
import 'format/resolve-image-format.rule.dart';
import 'format/resolve-inline-format.rule.dart';
import 'format/resolve-line-format.rule.dart';
import 'insert/auto-exit-block.rule.dart';
import 'insert/auto-format-links.rule.dart';
import 'insert/auto-format-multiple-links.rule.dart';
import 'insert/catch-all-insert.rule.dart';
import 'insert/insert-embeds.rule.dart';
import 'insert/preserve-block-style-on-insert.rule.dart';
import 'insert/preserve-inline-styles.rule.dart';
import 'insert/preserve-line-style-on-split.rule.dart';
import 'insert/reset-line-format-on-new-line.rule.dart';

// Rules are middleware used to control the behavior of document edit operations.
// There ar 3 types of rules: for formatting, insertion and deletion.
// On each document operation the rules list is used to generate a new delta.
// This new delta is composed in the document.
// When composing the delta is iterated and nodes are update accordingly.
// Nodes are mapped to actual text spans, each one containing an unique set of text attributes.
// After the nodes have been updated a new delta is generated
// out of the nodes and cached in the document.
class RulesController {
  final _du = DeltaUtils();
  
  final List<RuleM> _rules = [
    // Format
    FormatLinkAtCaretPositionRule(),
    ResolveLineFormatRule(),
    ResolveInlineFormatRule(),
    ResolveImageFormatRule(),

    // Insert
    InsertEmbedsRule(),
    AutoExitBlockRule(),
    PreserveBlockStyleOnInsertRule(),
    PreserveLineStyleOnSplitRule(),
    ResetLineFormatOnNewLineRule(),
    AutoFormatLinksRule(),
    AutoFormatMultipleLinksRule(),
    PreserveInlineStylesRule(),

    // Delete
    CatchAllInsertRule(),
    EnsureEmbedLineRule(),
    PreserveLineStyleOnMergeRule(),
    CatchAllDeleteRule(),
    EnsureLastLineBreakDeleteRule()
  ];
  List<RuleM> _customRules = [];

  void setCustomRules(List<RuleM> customRules) {
    _customRules = customRules;
  }

  DeltaM apply(
    RuleTypeE ruleType,
    DocumentM document,
    int index, {
    required String plainText,
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    final currDelta = document.delta;

    for (final rule in _customRules + _rules) {
      if (rule.type != ruleType) {
        continue;
      }

      try {
        final deltaRes = rule.apply(
          currDelta,
          index,
          len: len,
          data: data,
          attribute: attribute,
          plainText: plainText,
        );

        if (deltaRes != null) {
          _du.trim(deltaRes);

          return deltaRes;
        }
      } catch (e) {
        print('Applying the Rules Failed with error in rule "$rule": $e');
        // TODO Review why rethrow does not work
        rethrow;
      }
    }

    throw 'Apply rules failed';
  }
}
