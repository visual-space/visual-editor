import 'package:quiver/core.dart';

import '../../services/delta.utils.dart';
import '../../services/nodes/operations.utils.dart';
import 'data-decoder.type.dart';
import 'operation.model.dart';

final _du = DeltaUtils();
final _opUtils = OperationsUtils();

// Implementation of Quill Delta format in Dart.
// Delta represents a document or a modification of a document as a sequence of insert, delete and retain operations.
// Delta documents are basically lists of operations.
// Delta consisting of only "insert" operations is usually referred to as "document delta".
// When delta includes also "retain" or "delete" operations it is a "change delta".
// Deltas are processed by the rules engine operation by operation.
// The result of processing the operations is a list of document nodes.
// Each document node describes a segment of text with distinct styling.
// Nodes are mapped to text/widget spans during the build().
// To maintain a condensed API Method names have been kept short.
class DeltaM {
  late final List<OperationM> operations;
  int _modificationCount = 0;

  // Creates new empty DeltaM.
  DeltaM([List<OperationM>? _operations]) {
    operations = _operations ?? [];
  }

  // TODO Needs to be improved to create a deep clone (even the Quill version is badly implemented)
  DeltaM.from(DeltaM newDelta) {
    operations = newDelta.operations;
  }

  static DeltaM fromJson(List jsonOps, {DataDecoder? dataDecoder}) =>
      _du.fromJson(jsonOps, dataDecoder: dataDecoder);

  // === QUERIES ===

  @override
  String toString() => operations.join('\n');

  @override
  int get hashCode => hashObjects(operations);

  @override
  bool operator ==(dynamic newDelta) => _du.equals(operations, newDelta);

  int get modificationCount => _modificationCount;

  List<OperationM> toList() => List.from(operations);

  List toJson() => toList().map(_opUtils.toJson).toList();

  bool get isEmpty => operations.isEmpty;

  bool get isNotEmpty => operations.isNotEmpty;

  int get length => operations.length;

  OperationM operator [](int index) => operations[index];

  OperationM elementAt(int index) => operations.elementAt(index);

  OperationM get first => operations.first;

  OperationM get last => operations.last;

  // === UTILS ===

  // Returns a new lazy Iterable with elements that are created by calling
  // if on each element of this Iterable in iteration order. (convenience method)
  Iterable<T> map<T>(T Function(OperationM) f) => operations.map<T>(f);

  void incrementModificationCount() => _modificationCount++;
}
