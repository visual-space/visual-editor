import 'package:quiver/core.dart';

import 'attribute-scope.enum.dart';
import 'attributes/attributes-types.model.dart';

// Attributes defined the characteristics of text.
// The delta document stores attributes for each operation.
// @immutable TODO
class AttributeM<T> {
  final String key;
  final AttributeScope scope;
  final T value;

  bool get isInline => scope == AttributeScope.INLINE;

  bool get isBlockExceptHeader =>
      AttributesTypesM.blockKeysExceptHeader.contains(key);

  AttributeM(
    this.key,
    this.scope,
    this.value,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{key: value};

  @override
  String toString() {
    return 'AttributeM(key: $key, scope: $scope, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! AttributeM) {
      return false;
    }

    final typedOther = other;

    return key == typedOther.key &&
        scope == typedOther.scope &&
        value == typedOther.value;
  }

  @override
  int get hashCode => hash3(key, scope, value);
}
