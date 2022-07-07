import 'dart:collection';

import '../attribute.model.dart';
import 'attributes.model.dart';

// Used for sorting the order of the attributes
final Map<String, AttributeM> attributesRegistry = LinkedHashMap.of({
  AttributesM.bold.key: AttributesM.bold,
  AttributesM.italic.key: AttributesM.italic,
  AttributesM.small.key: AttributesM.small,
  AttributesM.underline.key: AttributesM.underline,
  AttributesM.strikeThrough.key: AttributesM.strikeThrough,
  AttributesM.inlineCode.key: AttributesM.inlineCode,
  AttributesM.font.key: AttributesM.font,
  AttributesM.size.key: AttributesM.size,
  AttributesM.link.key: AttributesM.link,
  AttributesM.color.key: AttributesM.color,
  AttributesM.background.key: AttributesM.background,
  AttributesM.placeholder.key: AttributesM.placeholder,
  AttributesM.markers.key: AttributesM.markers,
  AttributesM.header.key: AttributesM.header,
  AttributesM.align.key: AttributesM.align,
  AttributesM.direction.key: AttributesM.direction,
  AttributesM.list.key: AttributesM.list,
  AttributesM.codeBlock.key: AttributesM.codeBlock,
  AttributesM.blockQuote.key: AttributesM.blockQuote,
  AttributesM.indent.key: AttributesM.indent,
  AttributesM.width.key: AttributesM.width,
  AttributesM.height.key: AttributesM.height,
  AttributesM.style.key: AttributesM.style,
  AttributesM.token.key: AttributesM.token,
  AttributesM.script.key: AttributesM.script,
});
