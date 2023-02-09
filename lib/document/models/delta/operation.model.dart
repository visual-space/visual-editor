import '../../services/nodes/operations.utils.dart';
import 'operations.enum.dart';

final _opUtils = OperationsUtils();

// Operation performed on a rich-text document.
// Delta documents are basically lists of operations.
// - insert - inserts text in the document (applies styles)
// - delete - deletes text
// - retain - jumps over a length of chars
// Deltas are processed by the rules engine operation by operation.
// The result of processing the operations list via the doc controller is a list of document nodes.
// Each document node describes a segment of text with distinct styling.
// Nodes are mapped to text/widget spans during the build().
// To maintain a condensed API Method names have been kept short.
class OperationM {
  // Key of this operation (insert, delete, retain)
  final String key;

  // Length of this operation.
  final int? length;

  // Payload of "insert" operation.
  // For other types is set to empty string.
  final Object? data;

  late final Map<String, dynamic>? attributes;

  OperationM(
    this.key,
    this.length,
    this.data,
    Map? _attributes,
  ) {
    assert(VALID_OP_KEYS.contains(key), 'Invalid operation key "$key".');
    assert(
      _opUtils.checkLengthAndOperationLengthAreEqual(this),
      'Length of insert operation must be equal to the data length.',
    );
    attributes =
        _attributes != null ? Map<String, dynamic>.from(_attributes) : null;
  }

  // === QUERIES ===

  @override
  String toString() => _opUtils.opToString(this);

  // Returns value of this operation.
  // For insert operations this returns text, for delete and retain - length.
  dynamic get value => (key == INSERT_KEY) ? data : length;

  bool get isDelete => key == DELETE_KEY;

  bool get isInsert => key == INSERT_KEY;

  bool get isRetain => key == RETAIN_KEY;

  // E.g. is plain text.
  bool get isPlain => attributes == null || attributes!.isEmpty;

  // Operation sets at least one attribute.
  bool get isNotPlain => !isPlain;

  // An operation is considered empty if its [length] is equal to `0`.
  bool get isEmpty => length == 0;

  bool get isNotEmpty => length! > 0;

  // Operation has attribute specified by [name].
  bool hasAttribute(String name) => isNotPlain && attributes!.containsKey(name);
}
