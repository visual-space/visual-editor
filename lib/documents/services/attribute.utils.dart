import '../models/attribute.model.dart';
import '../models/attributes/attributes-aliases.model.dart';
import '../models/attributes/attributes-registry.const.dart';
import '../models/attributes/styling-attributes.dart';

// Attributes defined the characteristics of text.
// The delta document stores attributes for each operation.
class AttributeUtils {
  static AttributeM<int?> getIndentLevel(int? level) {
    if (level == 1) {
      return AttributesAliasesM.indentL1;
    }

    if (level == 2) {
      return AttributesAliasesM.indentL2;
    }

    if (level == 3) {
      return AttributesAliasesM.indentL3;
    }

    return IndentAttributeM(
      level: level,
    );
  }

  static AttributeM? fromKeyValue(String key, dynamic value) {
    final origin = attributesRegistry[key];

    if (origin == null) {
      return null;
    }

    final attribute = clone(origin, value);

    return attribute;
  }

  static int getRegistryOrder(AttributeM attribute) {
    var order = 0;

    for (final attr in attributesRegistry.values) {
      if (attr.key == attribute.key) {
        break;
      }

      order++;
    }

    return order;
  }

  static AttributeM clone(AttributeM origin, dynamic value) {
    return AttributeM(
      origin.key,
      origin.scope,
      value,
    );
  }
}
