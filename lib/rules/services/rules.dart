import '../../../documents/models/attribute.dart';
import '../../../documents/models/document.dart';
import '../../../rules/models/rule-type.enum.dart';
import '../../delta/models/delta.model.dart';
import '../models/rule.model.dart';
import 'delete.dart';
import 'format.dart';
import 'insert.dart';

// Each editor can have it's own set of rules.
// Therefore this is not a singleton class.
class Rules {
  Rules(this._rules);

  List<RuleM> _customRules = [];

  final List<RuleM> _rules;
  static final Rules _instance = Rules([
    const FormatLinkAtCaretPositionRule(),
    const ResolveLineFormatRule(),
    const ResolveInlineFormatRule(),
    const ResolveImageFormatRule(),
    const InsertEmbedsRule(),
    const AutoExitBlockRule(),
    const PreserveBlockStyleOnInsertRule(),
    const PreserveLineStyleOnSplitRule(),
    const ResetLineFormatOnNewLineRule(),
    const AutoFormatLinksRule(),
    const AutoFormatMultipleLinksRule(),
    const PreserveInlineStylesRule(),
    const CatchAllInsertRule(),
    const EnsureEmbedLineRule(),
    const PreserveLineStyleOnMergeRule(),
    const CatchAllDeleteRule(),
    const EnsureLastLineBreakDeleteRule()
  ]);

  static Rules getInstance() => _instance;

  void setCustomRules(List<RuleM> customRules) {
    _customRules = customRules;
  }

  DeltaM apply(
    RuleTypeE ruleType,
    Document document,
    int index, {
    int? len,
    Object? data,
    Attribute? attribute,
  }) {
    final delta = document.toDelta();

    for (final rule in _customRules + _rules) {
      if (rule.type != ruleType) {
        continue;
      }
      try {
        final result = rule.apply(
          delta,
          index,
          len: len,
          data: data,
          attribute: attribute,
        );

        if (result != null) {
          return result..trim();
        }
      } catch (e) {
        rethrow;
      }
    }
    throw 'Apply rules failed';
  }
}
