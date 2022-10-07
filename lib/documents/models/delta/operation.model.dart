import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

import 'data-decoder.type.dart';

const _attributeEquality = DeepCollectionEquality();
const _valueEquality = DeepCollectionEquality();

// Operation performed on a rich-text document.
class OperationM {
  // Default data decoder which simply passes through the original value.
  static Object? _passThroughDataDecoder(Object? data) => data;

  OperationM(
    this.key,
    this.length,
    this.data,
    Map? attributes,
  )   : assert(_validKeys.contains(key), 'Invalid operation key "$key".'),
        assert(
          () {
            if (key != OperationM.insertKey) return true;
            return data is String ? data.length == length : length == 1;
          }(),
          'Length of insert operation must be equal to the data length.',
        ),
        _attributes =
            attributes != null ? Map<String, dynamic>.from(attributes) : null;

  // Deletes length of characters.
  factory OperationM.delete(int length) =>
      OperationM(OperationM.deleteKey, length, '', null);

  // Inserts text with optional attributes.
  factory OperationM.insert(dynamic data, [Map<String, dynamic>? attributes]) =>
      OperationM(OperationM.insertKey, data is String ? data.length : 1, data,
          attributes);

  // Retains length of characters and optionally applies attributes.
  factory OperationM.retain(int? length, [Map<String, dynamic>? attributes]) =>
      OperationM(OperationM.retainKey, length, '', attributes);

  // TODO Move to enum
  static const String insertKey = 'insert';

  static const String deleteKey = 'delete';

  // Retains length of characters and optionally applies attributes.
  // This is useful when you want to apply changes on the same delta without progressing to the next operation.
  static const String retainKey = 'retain';

  static const String attributesKey = 'attributes';

  static const List<String> _validKeys = [insertKey, deleteKey, retainKey];

  // Key of this operation.
  // Can be "insert", "delete" or "retain".
  final String key;

  // TODO Dow really woant optional value here? Should be guaranteed with fail safe to zero.
  // Length of this operation.
  final int? length;

  // Payload of "insert" operation.
  // For other types is set to empty string.
  final Object? data;

  // Rich-text attributes set by this operation, can be `null`.
  Map<String, dynamic>? get attributes =>
      _attributes == null ? null : Map<String, dynamic>.from(_attributes!);
  final Map<String, dynamic>? _attributes;

  // Creates new [Operation] from JSON payload.
  // If `dataDecoder` parameter is not null then it is used to additionally decode the operation's data object. Only applied to insert operations.
  static OperationM fromJson(Map data, {DataDecoder? dataDecoder}) {
    dataDecoder ??= _passThroughDataDecoder;
    final map = Map<String, dynamic>.from(data);

    if (map.containsKey(OperationM.insertKey)) {
      final data = dataDecoder(map[OperationM.insertKey]);
      final dataLength = data is String ? data.length : 1;
      return OperationM(
        OperationM.insertKey,
        dataLength,
        data,
        map[OperationM.attributesKey],
      );
    } else if (map.containsKey(OperationM.deleteKey)) {
      final int? length = map[OperationM.deleteKey];
      return OperationM(OperationM.deleteKey, length, '', null);
    } else if (map.containsKey(OperationM.retainKey)) {
      final int? length = map[OperationM.retainKey];
      return OperationM(
        OperationM.retainKey,
        length,
        '',
        map[OperationM.attributesKey],
      );
    }
    throw ArgumentError.value(data, 'Invalid data for Delta operation.');
  }

  // Returns JSON-serializable representation of this operation.
  Map<String, dynamic> toJson() {
    final json = {key: value};
    if (_attributes != null) json[OperationM.attributesKey] = attributes;
    return json;
  }

  // Returns value of this operation.
  // For insert operations this returns text, for delete and retain - length.
  dynamic get value => (key == OperationM.insertKey) ? data : length;

  bool get isDelete => key == OperationM.deleteKey;

  bool get isInsert => key == OperationM.insertKey;

  bool get isRetain => key == OperationM.retainKey;

  // E.g. is plain text.
  bool get isPlain => _attributes == null || _attributes!.isEmpty;

  // Operation sets at least one attribute.
  bool get isNotPlain => !isPlain;

  // An operation is considered empty if its [length] is equal to `0`.
  bool get isEmpty => length == 0;

  bool get isNotEmpty => length! > 0;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! OperationM) return false;
    final typedOther = other;
    return key == typedOther.key &&
        length == typedOther.length &&
        _valueEquality.equals(data, typedOther.data) &&
        hasSameAttributes(typedOther);
  }

  // Operation has attribute specified by [name].
  bool hasAttribute(String name) =>
      isNotPlain && _attributes!.containsKey(name);

  // other operation has the same attributes as this one.
  bool hasSameAttributes(OperationM other) {
    // Treat null and empty equal
    if ((_attributes?.isEmpty ?? true) &&
        (other._attributes?.isEmpty ?? true)) {
      return true;
    }

    return _attributeEquality.equals(_attributes, other._attributes);
  }

  @override
  int get hashCode {
    if (_attributes != null && _attributes!.isNotEmpty) {
      final attrsHash = hashObjects(
        _attributes!.entries.map(
          (e) => hash2(e.key, e.value),
        ),
      );

      return hash3(key, value, attrsHash);
    }

    return hash2(key, value);
  }

  @override
  String toString() {
    final attr = attributes == null ? '' : ' + $attributes';
    final text = isInsert
        ? (data is String
            ? (data as String).replaceAll('\n', '⏎')
            : data.toString())
        : '$length';

    return '$key⟨ $text ⟩$attr';
  }
}
