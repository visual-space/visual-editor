import 'dart:math' as math;

import '../models/delta/delta.model.dart';
import '../models/delta/operation.model.dart';
import '../models/delta/operations.enum.dart';
import '../services/nodes/operations.utils.dart';

final _opUtils = OperationsUtils();

// Specialized iterator for Delta models.
// Iterators are necessary for most text editing operations.
// They increment operation by operation the deltas, especially useful when comparing deltas.
class DeltaIterator {
  DeltaIterator(this.delta) : _modificationCount = delta.modificationCount;

  static const int maxLength = 1073741824;

  final DeltaM delta;
  final int _modificationCount;
  int _index = 0;
  int _offset = 0;

  bool get isNextInsert => nextOperationKey == INSERT_KEY;

  bool get isNextDelete => nextOperationKey == DELETE_KEY;

  bool get isNextRetain => nextOperationKey == RETAIN_KEY;

  String? get nextOperationKey {
    if (_index < delta.length) {
      return delta.elementAt(_index).key;
    } else {
      return null;
    }
  }

  bool get hasNext => peekLength() < maxLength;

  // Returns length of next operation without consuming it.
  // Returns maxLength if there is no more operations left to iterate.
  int peekLength() {
    if (_index < delta.length) {
      final operation = delta.operations[_index];

      return operation.length! - _offset;
    }

    return maxLength;
  }

  // Consumes and returns next operation.
  // Optional length specifies maximum length of operation to return. Note
  // that actual length of returned operation may be less than specified value.
  // If this iterator reached the end of the Delta then returns a retain
  // operation with its length set to maxLength.

  // TODO: Note that we used double.infinity as the default value
  // For length here but this can now cause a type error since operation length is expected to be an int.
  // Changing default length to maxLength is a workaround to avoid breaking changes.
  OperationM next([int length = maxLength]) {
    if (_modificationCount != delta.modificationCount) {
      throw ConcurrentModificationError(delta);
    }

    if (_index < delta.length) {
      final operation = delta.elementAt(_index);
      final opKey = operation.key;
      final opAttributes = operation.attributes;
      final _currentOffset = _offset;
      final actualLength = math.min(operation.length! - _currentOffset, length);

      if (actualLength == operation.length! - _currentOffset) {
        _index++;
        _offset = 0;
      } else {
        _offset += actualLength;
      }

      final opData = operation.isInsert && operation.data is String
          ? (operation.data as String)
          .substring(_currentOffset, _currentOffset + actualLength)
          : operation.data;
      final opIsNotEmpty =
      opData is String ? opData.isNotEmpty : true; // embeds are never empty
      final opLength = opData is String ? opData.length : 1;
      final opActualLength = opIsNotEmpty ? opLength : actualLength;

      return OperationM(opKey, opActualLength, opData, opAttributes);
    }

    return _opUtils.getRetainOp(length);
  }

  // Skips length characters in source delta.
  // Returns last skipped operation, or `null` if there was nothing to skip.
  OperationM? skip(int length) {
    var skipped = 0;
    OperationM? operation;

    while (skipped < length && hasNext) {
      final opLength = peekLength();
      final skip = math.min(length - skipped, opLength);
      operation = next(skip);
      skipped += operation.length!;
    }

    return operation;
  }
}
