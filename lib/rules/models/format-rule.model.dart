import '../../documents/models/attribute.model.dart';
import '../models/rule-type.enum.dart';
import '../models/rule.model.dart';

/// A heuristic rule for format (retain) operations.
abstract class FormatRuleM extends RuleM {
  const FormatRuleM();

  @override
  RuleTypeE get type => RuleTypeE.FORMAT;

  @override
  void validateArgs(
    int? len,
    Object? data,
    AttributeM? attribute,
  ) {
    assert(len != null);
    assert(data == null);
    assert(attribute != null);
  }
}
