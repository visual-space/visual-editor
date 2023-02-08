import 'package:collection/collection.dart';

import '../../services/nodes/attribute.utils.dart';
import '../../services/nodes/styles.utils.dart';
import '../attributes/attribute.model.dart';

final _styleUtils = StylesUtils();

// Collection of style attributes.
// Operations have an associated styles model.
class StyleM {
  final Map<String, AttributeM> attributes;

  Iterable<String> get keys => attributes.keys;

  Iterable<AttributeM> get values => attributes.values.sorted(
        (a, b) =>
            AttributeUtils.getRegistryOrder(a) -
            AttributeUtils.getRegistryOrder(b),
      );

  bool get isEmpty => attributes.isEmpty;

  bool get isNotEmpty => attributes.isNotEmpty;

  bool get isInline => isNotEmpty && values.every((item) => item.isInline);

  bool get isIgnored => _styleUtils.getIsIgnored(this);

  AttributeM get single => attributes.values.single;

  StyleM() : attributes = <String, AttributeM>{};

  @override
  bool operator ==(Object other) => _styleUtils.isEqual(this, other);

  @override
  int get hashCode => _styleUtils.getHashCode(this);

  @override
  String toString() => "{${attributes.values.join(', ')}}";

  bool containsKey(String key) => attributes.containsKey(key);

  StyleM.attr(this.attributes);

  Map<String, dynamic>? toJson() => _styleUtils.styleToJson(this);
}
