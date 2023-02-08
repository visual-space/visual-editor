import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

import '../../models/delta/data-decoder.type.dart';
import '../../models/delta/operation.model.dart';
import '../../models/delta/operations.enum.dart';

const _attributeEquality = DeepCollectionEquality();
const _valueEquality = DeepCollectionEquality();

// Operation performed on a rich-text document.
// Delta documents are basically lists of operations.
class OperationsUtils {
  // === CONSTRUCTORS ===

  // Deletes length of characters.
  OperationM getDeleteOp(int length) {
    return OperationM(DELETE_KEY, length, '', null);
  }

  // Inserts text with optional attributes.
  OperationM getInsertOp(dynamic data, [Map<String, dynamic>? attributes]) {
    final length = data is String ? data.length : 1;
    return OperationM(INSERT_KEY, length, data, attributes);
  }

  // Retains length of characters and optionally applies attributes.
  OperationM getRetainOp(int? length, [Map<String, dynamic>? attributes]) {
    return OperationM(RETAIN_KEY, length, '', attributes);
  }

  // === OVERRIDES ===

  // Checks two ops for deep equality
  bool equals(OperationM op, dynamic newOp) {
    if (identical(this, newOp)) {
      return true;
    }

    if (newOp is! OperationM) {
      return false;
    }

    final _newOp = newOp;

    return op.key == _newOp.key &&
        op.length == _newOp.length &&
        _valueEquality.equals(op.data, _newOp.data) &&
        hasSameAttributes(op, _newOp);
  }

  int getHashCode(OperationM op) {
    if (op.attributes != null && op.attributes!.isNotEmpty) {
      final attrsHash = hashObjects(
        op.attributes!.entries.map(
          (e) => hash2(e.key, e.value),
        ),
      );

      return hash3(op.key, op.value, attrsHash);
    }

    return hash2(op.key, op.value);
  }

  String opToString(OperationM op) {
    final attr = op.attributes == null ? '' : ' + ${op.attributes}';
    final text = op.isInsert
        ? (op.data is String
            ? (op.data as String).replaceAll('\n', '⏎')
            : op.data.toString())
        : '${op.length}';

    return '${op.key}⟨ $text ⟩$attr';
  }

  // === JSON ===

  // Creates new [Operation] from JSON payload.
  // If `dataDecoder` parameter is not null then it is used to additionally decode
  // the operation's data object. Only applied to insert operations.
  OperationM fromJson(Map data, {DataDecoder? dataDecoder}) {
    dataDecoder ??= _passThroughDataDecoder;
    final map = Map<String, dynamic>.from(data);

    if (map.containsKey(INSERT_KEY)) {
      final data = dataDecoder(map[INSERT_KEY]);
      final dataLength = data is String ? data.length : 1;

      return OperationM(INSERT_KEY, dataLength, data, map[ATTRIBUTES_KEY]);
    } else if (map.containsKey(DELETE_KEY)) {
      final int? length = map[DELETE_KEY];

      return OperationM(DELETE_KEY, length, '', null);
    } else if (map.containsKey(RETAIN_KEY)) {
      final int? length = map[RETAIN_KEY];

      return OperationM(RETAIN_KEY, length, '', map[ATTRIBUTES_KEY]);
    }

    throw ArgumentError.value(data, 'Invalid data for Delta operation.');
  }

  // Returns JSON-serializable representation of this operation.
  Map<String, dynamic> toJson(OperationM op) {
    final json = {op.key: op.value};

    if (op.attributes != null) {
      json[ATTRIBUTES_KEY] = getOpAttributes(op);
    }

    return json;
  }

  // === QUERIES ===

  // Rich-text attributes set by this operation, can be `null`.
  Map<String, dynamic>? getOpAttributes(OperationM op) {
    return op.attributes == null ? null : Map<String, dynamic>.from(op.attributes!);
  }

  // other operation has the same attributes as this one.
  bool hasSameAttributes(OperationM op, OperationM newOp) {
    // Treat null and empty equal
    if ((op.attributes?.isEmpty ?? true) &&
        (newOp.attributes?.isEmpty ?? true)) {
      return true;
    }

    return _attributeEquality.equals(op.attributes, newOp.attributes);
  }

  // === PRIVATE ===

  // Default data decoder which simply passes through the original value.
  static Object? _passThroughDataDecoder(Object? data) {
    return data;
  }

  bool checkLengthAndOperationLengthAreEqual(OperationM op) {
    if (op.key != INSERT_KEY) {
      return true;
    }

    final _data = op.data;

    return _data is String ? _data.length == op.length : op.length == 1;
  }
}
