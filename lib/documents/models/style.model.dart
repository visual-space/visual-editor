import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

import '../services/attribute.utils.dart';
import 'attribute-scope.enum.dart';
import 'attribute.model.dart';
import 'attributes/attributes-types.model.dart';
import 'attributes/attributes.model.dart';

// Collection of style attributes.
// Operations have an associated styles model.
class StyleM {
  StyleM() : _attributes = <String, AttributeM>{};

  final Map<String, AttributeM> _attributes;

  Iterable<String> get keys => _attributes.keys;

  Iterable<AttributeM> get values => _attributes.values.sorted(
        (a, b) =>
            AttributeUtils.getRegistryOrder(a) -
            AttributeUtils.getRegistryOrder(b),
      );

  Map<String, AttributeM> get attributes => _attributes;

  bool get isEmpty => _attributes.isEmpty;

  bool get isNotEmpty => _attributes.isNotEmpty;

  bool get isInline => isNotEmpty && values.every((item) => item.isInline);

  bool get isIgnored =>
      isNotEmpty &&
      values.every(
        (item) => item.scope == AttributeScope.IGNORE,
      );

  AttributeM get single => _attributes.values.single;

  bool containsKey(String key) => _attributes.containsKey(key);

  StyleM.attr(this._attributes);

  // Converts the style attributes found in the delta json to model classes.
  // One special case was added for the markers model (explained bellow).
  static StyleM fromJson(Map<String, dynamic>? attributes) {

    // Empty Default
    if (attributes == null) {
      return StyleM();
    }

    final styleAttributes = attributes.map((attrKey, dynamic attrValue) {

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

  Map<String, dynamic>? toJson() => _attributes.isEmpty
      ? null
      : _attributes.map<String, dynamic>(
          (_, attribute) => MapEntry<String, dynamic>(
            attribute.key,
            attribute.value,
          ),
        );

  // === UTILS ===

  AttributeM? getBlockExceptHeader() {
    for (final val in values) {
      if (val.isBlockExceptHeader && val.value != null) {
        return val;
      }
    }

    for (final val in values) {
      if (val.isBlockExceptHeader) {
        return val;
      }
    }

    return null;
  }

  Map<String, AttributeM> getBlocksExceptHeader() {
    final m = <String, AttributeM>{};

    attributes.forEach((key, value) {
      if (AttributesTypesM.blockKeysExceptHeader.contains(key)) {
        m[key] = value;
      }
    });

    return m;
  }

  StyleM merge(AttributeM attribute) {
    final merged = Map<String, AttributeM>.from(_attributes);

    if (attribute.value == null) {
      merged.remove(attribute.key);
    } else {
      merged[attribute.key] = attribute;
    }

    return StyleM.attr(merged);
  }

  StyleM mergeAll(StyleM other) {
    var result = StyleM.attr(_attributes);

    for (final attribute in other.values) {
      result = result.merge(attribute);
    }

    return result;
  }

  StyleM removeAll(Set<AttributeM> attributes) {
    final merged = Map<String, AttributeM>.from(_attributes);
    attributes.map((item) => item.key).forEach(merged.remove);
    return StyleM.attr(merged);
  }

  StyleM put(AttributeM attribute) {
    final m = Map<String, AttributeM>.from(attributes);
    m[attribute.key] = attribute;

    return StyleM.attr(m);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! StyleM) {
      return false;
    }

    final typedOther = other;
    const eq = MapEquality<String, AttributeM>();

    return eq.equals(_attributes, typedOther._attributes);
  }

  @override
  int get hashCode {
    final hashes = _attributes.entries.map(
      (entry) => hash2(entry.key, entry.value),
    );

    return hashObjects(hashes);
  }

  @override
  String toString() => "{${_attributes.values.join(', ')}}";
}
