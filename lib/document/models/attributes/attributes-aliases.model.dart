import 'attribute.model.dart';
import 'styling-attributes.dart';

// Styling attributes with prebaked values.
// These avlues are selected to hardcode a finite set of styling states
class AttributesAliasesM {
  static AttributeM<int?> get h1 => HeaderAttributeM(level: 1);

  static AttributeM<int?> get h2 => HeaderAttributeM(level: 2);

  static AttributeM<int?> get h3 => HeaderAttributeM(level: 3);

  // "attributes": {"align": "left"}
  static AttributeM<String?> get leftAlignment => AlignAttributeM('left');

  // "attributes": {"align": "center"}
  static AttributeM<String?> get centerAlignment => AlignAttributeM('center');

  // "attributes": {"align": "right"}
  static AttributeM<String?> get rightAlignment => AlignAttributeM('right');

  // "attributes": {"align": "justify"}
  static AttributeM<String?> get justifyAlignment => AlignAttributeM('justify');

  // "attributes": {"list": "bullet"}
  static AttributeM<String?> get bulletList => ListAttributeM('bullet');

  // "attributes": {"list": "ordered"}
  static AttributeM<String?> get orderedList => ListAttributeM('ordered');

  // "attributes": {"list": "checked"}
  static AttributeM<String?> get checked => ListAttributeM('checked');

  // "attributes": {"list": "unchecked"}
  static AttributeM<String?> get unchecked => ListAttributeM('unchecked');

  // "attributes": {"direction": "rtl"}
  static AttributeM<String?> get rtl => DirectionAttributeM('rtl');

  // "attributes": {"indent": 1}
  static AttributeM<int?> get indentL1 => IndentAttributeM(level: 1);

  // "attributes": {"indent": 2}
  static AttributeM<int?> get indentL2 => IndentAttributeM(level: 2);

  // "attributes": {"indent": 3}
  static AttributeM<int?> get indentL3 => IndentAttributeM(level: 3);
}
