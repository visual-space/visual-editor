import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

import '../../models/attributes/attribute-scope.enum.dart';
import '../../models/attributes/attribute.model.dart';
import '../../models/attributes/attributes-types.model.dart';
import '../../models/attributes/attributes.model.dart';
import '../../models/nodes/style.model.dart';
import 'attribute.utils.dart';

class StylesUtils {
  bool getIsIgnored(StyleM style) =>
      style.isNotEmpty &&
      style.values.every(
        (item) => item.scope == AttributeScope.IGNORE,
      );

  bool isEqual(StyleM style, Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! StyleM) {
      return false;
    }

    final typedOther = other;
    const eq = MapEquality<String, AttributeM>();

    return eq.equals(style.attributes, typedOther.attributes);
  }

  int getHashCode(StyleM style) {
    final hashes = style.attributes.entries.map(
      (entry) => hash2(entry.key, entry.value),
    );

    return hashObjects(hashes);
  }

  // === JSON ===

  // Converts the style attributes found in the delta json to model classes.
  // One special case was added for the markers model (explained bellow).
  StyleM fromJson(Map<String, dynamic>? _attributes) {
    // Empty Default
    if (_attributes == null) {
      return StyleM();
    }

    final styleAttributes = _attributes.map((attrKey, dynamic attrValue) {
      // Most attributes are primitive values, therefore converting form json map to delta is straight forward.
      // However, markers are a special type of attribute with additional nesting.
      // For this particular attribute we need additional processing to extract the data types.
      // (!) Order matters. Prior to this we had a mistake by generating the models after the attribute was created.
      // Therefore all the code downstream was built using the json data instead of the delta models.
      if (attrKey == AttributesM.markers.key) {
        attrValue = AttributeUtils.extractMarkersFromAttributeMap(attrValue);
      }

      final attribute = AttributeUtils.fromKeyValue(attrKey, attrValue);

      return MapEntry<String, AttributeM>(
        attrKey,

        // Fail safe
        attribute ?? AttributeM(attrKey, AttributeScope.INLINE, attrValue),
      );
    });

    return StyleM.attr(styleAttributes);
  }

  Map<String, dynamic>? styleToJson(StyleM style) => style.attributes.isEmpty
      ? null
      : style.attributes.map<String, dynamic>(
          (_, attribute) => MapEntry<String, dynamic>(
            attribute.key,
            attribute.value,
          ),
        );

  // === OPERATIONS ===

  AttributeM? getBlockExceptHeader(StyleM style) {
    for (final val in style.values) {
      if (val.isBlockExceptHeader && val.value != null) {
        return val;
      }
    }

    for (final val in style.values) {
      if (val.isBlockExceptHeader) {
        return val;
      }
    }

    return null;
  }

  Map<String, AttributeM> getBlocksExceptHeader(StyleM style) {
    final newAttrs = <String, AttributeM>{};

    style.attributes.forEach((key, value) {
      if (AttributesTypesM.blockKeysExceptHeader.contains(key)) {
        newAttrs[key] = value;
      }
    });

    return newAttrs;
  }

  StyleM merge(StyleM style, AttributeM attribute) {
    final merged = Map<String, AttributeM>.from(style.attributes);

    if (attribute.value == null) {
      merged.remove(attribute.key);
    } else {
      merged[attribute.key] = attribute;
    }

    return StyleM.attr(merged);
  }

  StyleM mergeAll(StyleM style, StyleM other) {
    var result = StyleM.attr(style.attributes);

    for (final attribute in other.values) {
      result = merge(result, attribute);
    }

    return result;
  }

  StyleM removeAll(StyleM style, Set<AttributeM> _attributes) {
    final merged = Map<String, AttributeM>.from(style.attributes);
    _attributes.map((item) => item.key).forEach(merged.remove);
    return StyleM.attr(merged);
  }

  StyleM put(StyleM style, AttributeM attribute) {
    final newAttrs = Map<String, AttributeM>.from(style.attributes);
    newAttrs[attribute.key] = attribute;

    return StyleM.attr(newAttrs);
  }
}
