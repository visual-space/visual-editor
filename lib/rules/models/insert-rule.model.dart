import '../../documents/models/attribute.dart';
import '../models/rule-type.enum.dart';
import '../models/rule.model.dart';

/// A heuristic rule for insert operations.
abstract class InsertRuleM extends RuleM {
  const InsertRuleM();

  @override
  RuleTypeE get type => RuleTypeE.INSERT;

  @override
  void validateArgs(
    int? len,
    Object? data,
    Attribute? attribute,
  ) {
    assert(data != null);
    assert(attribute == null);
  }
}
