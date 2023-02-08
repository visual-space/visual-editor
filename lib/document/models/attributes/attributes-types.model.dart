import 'dart:collection';

import 'attributes.model.dart';

// Each group enables a custom behaviour for the selected attributes.
class AttributesTypesM {
  static final Set<String> inlineKeys = {
    AttributesM.bold.key,
    AttributesM.italic.key,
    AttributesM.small.key,
    AttributesM.underline.key,
    AttributesM.strikeThrough.key,
    AttributesM.link.key,
    AttributesM.color.key,
    AttributesM.background.key,
    AttributesM.placeholder.key,
    AttributesM.markers.key,
  };

  static final Set<String> blockKeys = LinkedHashSet.of({
    AttributesM.header.key,
    AttributesM.align.key,
    AttributesM.list.key,
    AttributesM.codeBlock.key,
    AttributesM.blockQuote.key,
    AttributesM.indent.key,
    AttributesM.direction.key,
  });

  // Some rules apply to doc-tree only.
  // For example, we an press enter twice and we need to exit the block.
  // This list helps us detect lines of code belonging to one of the known block types.
  static final Set<String> blockKeysExceptHeader = LinkedHashSet.of({
    AttributesM.list.key,
    AttributesM.align.key,
    AttributesM.codeBlock.key,
    AttributesM.blockQuote.key,
    AttributesM.indent.key,
    AttributesM.direction.key,
  });

  static final Set<String> exclusiveBlockKeys = LinkedHashSet.of({
    AttributesM.header.key,
    AttributesM.list.key,
    AttributesM.codeBlock.key,
    AttributesM.blockQuote.key,
  });
}
