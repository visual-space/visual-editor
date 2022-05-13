import '../../delta/models/delta.model.dart';
import '../../documents/models/attribute.dart';
import 'rule-type.enum.dart';

abstract class RuleM {
  const RuleM();

  DeltaM? apply(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    Attribute? attribute,
  }) {
    validateArgs(len, data, attribute);
    return applyRule(
      document,
      index,
      len: len,
      data: data,
      attribute: attribute,
    );
  }

  void validateArgs(
    int? len,
    Object? data,
    Attribute? attribute,
  );

  // Applies heuristic rule to an operation on a [document] and returns
  // resulting [DeltaM].
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    Attribute? attribute,
  });

  RuleTypeE get type;
}
