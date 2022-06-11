import '../../documents/models/attribute.model.dart';
import '../models/rule-type.enum.dart';
import '../models/rule.model.dart';

/// A heuristic rule for delete operations.
abstract class DeleteRuleM extends RuleM {
  const DeleteRuleM();

  @override
  RuleTypeE get type => RuleTypeE.DELETE;

  @override
  void validateArgs(int? len, Object? data, AttributeM? attribute) {
    assert(len != null);
    assert(data == null);
    assert(attribute == null);
  }
}
