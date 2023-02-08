import '../../document/models/attributes/attribute.model.dart';
import '../../document/models/delta/delta.model.dart';
import 'rule-type.enum.dart';

// Visual Editor (as in Quill) has a list of rules that are executed after each document change
// Rules are contain logic to be executed once a certain trigger/condition is fulfilled.
// For ex: One rule is to break out of doc-tree when 2 new white lines are inserted.
//   Such a rule will attempt to go trough the entire document and scan for lines of text
//   that match the condition: 2 white lines one after the other.
//   Once such a pair is detected, then we modify the second line styling to remove the block attribute.
// The example above illustrates one potential use case for rules.
// However there are many other operations that can be shared between multiple text editing operations.
// Most of them will need: index, length, document and the new attribute.
// Some rules will apply only to the current text selection, some will apply to the entire document.
// Each rule is free to decide how to approach solving it's particular problem.
// When the toolbar buttons are pressed, we prepare a style change for the document.
// Most of the toolbar buttons will use the current selection to apply style changes via controller.formatSelection().
// However it's possible to write code that does not depend on the selection and can be given any arbitrary range (including the full doc).
abstract class RuleM {
  const RuleM();

  DeltaM? apply(
    DeltaM docDelta,
    int index, {
    required String plainText,
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    validateArgs(len, data, attribute);

    return applyRule(
      docDelta,
      index,
      len: len,
      data: data,
      attribute: attribute,
      plainText: plainText,
    );
  }

  void validateArgs(
    int? len,
    Object? data,
    AttributeM? attribute,
  );

  // Applies heuristic rule to an operation on a [document] and returns resulting [DeltaM].
  DeltaM? applyRule(
    DeltaM docDelta,
    int index, {
    required String plainText,
    int? len,
    Object? data,
    AttributeM? attribute,
  });

  RuleTypeE get type;
}
