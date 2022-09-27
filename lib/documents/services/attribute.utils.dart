import '../../markers/models/marker.model.dart';
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

  // Given a key and a value it creates an Attribute model
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

  // Markers have additional nested metadata assigned to the value property.
  // Therefore we need to convert it to a MarkerM.
  static List<MarkerM>? extractMarkersFromAttributeMap(List<dynamic>? value) {
    // No markers on the attribute (fail safe)
    if (value == null) {
      return null;
    }

    final markers = <MarkerM>[];

    // Iterate the properties of the map object
    for (final marker in value) {
      final keys = marker.values.toList();

      // Type
      final id = keys[0];

      // Type
      final type = keys[1];

      // Data (if any)
      dynamic data;

      if (keys.length == 3) {
        data = marker.values.toList()[2];
      }

      markers.add(
        MarkerM(
          id: id,
          type: type,
          data: data,
        ),
      );
    }

    return markers;
  }
}
