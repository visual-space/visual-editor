import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/attributes/attributes.model.dart';
import '../../../documents/models/attributes/styling-attributes.dart';
import '../../../documents/models/delta/delta.model.dart';
import '../../../documents/models/document.model.dart';
import '../../models/insert-rule.model.dart';

// Applies link format to text segments within the inserted text that matches the URL pattern.
// The link attribute is applied as the user types.
class AutoFormatMultipleLinksRule extends InsertRuleM {
  const AutoFormatMultipleLinksRule();

  // Link pattern.
  // This pattern is used to match a links within a text segment.
  // It works for the following testing URLs:
  // www.google.com
  // http://google.com
  // https://www.google.com
  // http://beginner.example.edu/#act
  // https://birth.example.net/beds/ants.php#bait
  // http://example.com/babies
  // https://www.example.com/
  // https://attack.example.edu/?acoustics=blade&bed=bed
  // http://basketball.example.com/
  // https://birthday.example.com/birthday
  // http://www.example.com/
  // https://example.com/addition/action
  // http://example.com/
  // https://bite.example.net/#adjustment
  // http://www.example.net/badge.php?bedroom=anger
  // https://brass.example.com/?anger=branch&actor=amusement#adjustment
  // http://www.example.com/?action=birds&brass=apparatus
  // https://example.net/
  // URL generator tool (https://www.randomlists.com/urls) is used.
  static const _linkPattern =
      r'(https?:\/\/|www\.)[\w-\.]+\.[\w-\.]+(\/([\S]+)?)?';
  static final linkRegExp = RegExp(_linkPattern);

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    // Only format when inserting text.
    if (data is! String) return null;

    // Get current text.
    final entireText = DocumentM.fromDelta(document).toPlainText();

    // Get word before insertion.
    final leftWordPart = entireText
        // Keep all text before insertion.
        .substring(0, index)
        // Keep last paragraph.
        .split('\n')
        .last
        // Keep last word.
        .split(' ')
        .last
        .trimLeft();

    // Get word after insertion.
    final rightWordPart = entireText
        // Keep all text after insertion.
        .substring(index)
        // Keep first paragraph.
        .split('\n')
        .first
        // Keep first word.
        .split(' ')
        .first
        .trimRight();

    // Build the segment of affected words.
    final affectedWords = '$leftWordPart$data$rightWordPart';

    // Check for URL pattern.
    final matches = linkRegExp.allMatches(affectedWords);

    // If there are no matches, do not apply any format.
    if (matches.isEmpty) return null;

    // Build base delta.
    // The base delta is a simple insertion delta.
    final baseDelta = DeltaM()
      ..retain(index)
      ..insert(data);

    // Get unchanged text length.
    final unmodifiedLength = index - leftWordPart.length;

    // Create formatter delta.
    // The formatter delta will only include links formatting when needed.
    final formatterDelta = DeltaM()..retain(unmodifiedLength);

    var previousLinkEndRelativeIndex = 0;
    for (final match in matches) {
      // Get the size of the leading segment of text that is not part of the
      // link.
      final separationLength = match.start - previousLinkEndRelativeIndex;

      // Get the identified link.
      final link = affectedWords.substring(match.start, match.end);

      // Keep the leading segment of text and add link with its proper
      // attribute.
      formatterDelta
        ..retain(separationLength, AttributesM.link.toJson())
        ..retain(link.length, LinkAttributeM(link).toJson());

      // Update reference index.
      previousLinkEndRelativeIndex = match.end;
    }

    // Get remaining text length.
    final remainingLength = affectedWords.length - previousLinkEndRelativeIndex;

    // Remove links from remaining non-link text.
    formatterDelta.retain(remainingLength, AttributesM.link.toJson());

    // Build and return resulting change delta.
    return baseDelta.compose(formatterDelta);
  }
}
