import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:diff_match_patch/diff_match_patch.dart' as dmp;

import '../const/special-chars.const.dart';
import '../controllers/delta.iterator.dart';
import '../models/delta/data-decoder.type.dart';
import '../models/delta/delta.model.dart';
import '../models/delta/diff.model.dart';
import '../models/delta/operation.model.dart';
import 'nodes/operations.utils.dart';

// Handles the mutations of the delta operations list.
//
// Mutations
// - retain()
// - insert()
// - delete()
// - push()
// - compose()
// - trim()
// - trimNewLine()
//
// Functional
// - diff()
// - slice()
// - invert()
// - concat()
// - transform()
// - transformPosition()
class DeltaUtils {
  final _opUtils = OperationsUtils();

  // === OPERATIONS ===

  // Retain count of characters from current position (prevents modifications of text). (mutates delta)
  // Characters starting from current position to count (extent) will not be replaced be the following insert operation.
  void retain(
    DeltaM delta,
    int count, [
    Map<String, dynamic>? attributes,
  ]) {
    assert(count >= 0);

    // No-op
    if (count == 0) {
      return;
    }

    push(delta, _opUtils.getRetainOp(count, attributes));
  }

  // Insert data at current position. (mutates delta)
  void insert(
    DeltaM delta,
    dynamic data, [
    Map<String, dynamic>? attributes,
  ]) {
    // No-op
    if (data is String && data.isEmpty) {
      return;
    }

    push(delta, _opUtils.getInsertOp(data, attributes));
  }

  // Delete count characters from current position. (mutates delta)
  void delete(DeltaM delta, int count) {
    assert(count >= 0);

    if (count == 0) {
      return;
    }

    push(delta, _opUtils.getDeleteOp(count));
  }

  // Pushes new operation into this delta (merges inserts). (mutates delta)
  // Performs compaction by composing operation with current tail operation of this delta, when possible.
  // For instance, if current tail is `insert('abc')` and pushed operation is `insert('123')` then existing
  // tail is replaced with `insert('abc123')` - a compound result of the two operations.
  void push(DeltaM delta, OperationM operation) {
    if (operation.isEmpty) return;

    var index = delta.operations.length;
    final lastOp = delta.operations.isNotEmpty ? delta.operations.last : null;

    if (lastOp != null) {
      if (lastOp.isDelete && operation.isDelete) {
        _mergeWithTail(delta, operation);
        return;
      }

      if (lastOp.isDelete && operation.isInsert) {
        index -= 1; // Always insert before deleting
        final nLastOp = (index > 0) ? delta.operations.elementAt(index - 1) : null;

        if (nLastOp == null) {
          delta.operations.insert(0, operation);

          return;
        }
      }

      if (lastOp.isInsert && operation.isInsert) {
        if (_opUtils.hasSameAttributes(lastOp, operation) && operation.data is String && lastOp.data is String) {
          _mergeWithTail(delta, operation);

          return;
        }
      }

      if (lastOp.isRetain && operation.isRetain) {
        if (_opUtils.hasSameAttributes(lastOp, operation)) {
          _mergeWithTail(delta, operation);
          return;
        }
      }
    }

    if (index == delta.operations.length) {
      delta.operations.add(operation);
    } else {
      final opAtIndex = delta.operations.elementAt(index);
      delta.operations.replaceRange(index, index + 1, [operation, opAtIndex]);
    }

    delta.incrementModificationCount();
  }

  // Composes curr delta with new delta and returns new DeltaM. (Pure functional)
  // It is not required for curr and new delta to represent a document delta (consisting only of insert operations).
  DeltaM compose(DeltaM currDelta, DeltaM newDelta) {
    final deltaRes = DeltaM();
    final currIter = DeltaIterator(currDelta);
    final newIter = DeltaIterator(newDelta);

    while (currIter.hasNext || newIter.hasNext) {
      final newOp = _composeOperation(currIter, newIter);

      if (newOp != null) {
        push(deltaRes, newOp);
      }
    }

    trim(deltaRes);

    return deltaRes;
  }

  // Returns a DeltaM containing differences between 2 [DeltaM]s. (pure functional)
  // If cleanupSemantic is `true` (default), applies the following:
  // The diff of "mouse" and "sofas" is
  //   [delete(1), insert("s"), retain(1),
  //   delete("u"), insert("fa"), retain(1), delete(1)].
  // While this is the optimum diff, it is difficult for humans to understand.
  // Semantic cleanup rewrites the diff, expanding it into a more intelligible format.
  // The above example would become: [(-1, "mouse"), (1, "sofas")].
  // (source: https://github.com/google/diff-match-patch/wiki/API)
  // Useful when one wishes to display difference between 2 document
  DeltaM diff(
    DeltaM currDelta,
    DeltaM newDelta, {
    bool cleanupSemantic = true,
  }) {
    if (currDelta.operations.equals(newDelta.operations)) {
      return DeltaM();
    }

    final stringCurr = currDelta.map((operation) {
      if (operation.isInsert) {
        return operation.data is String ? operation.data : NULL_CHARACTER;
      }

      final prep = currDelta == newDelta ? 'on' : 'with';

      throw ArgumentError('diff() call $prep non-document');
    }).join();

    final stringNew = newDelta.map((operation) {
      if (operation.isInsert) {
        return operation.data is String ? operation.data : NULL_CHARACTER;
      }

      final prep = currDelta == newDelta ? 'on' : 'with';

      throw ArgumentError('diff() call $prep non-document');
    }).join();

    final diffDelta = DeltaM();
    final diffResult = dmp.diff(stringCurr, stringNew);

    if (cleanupSemantic) {
      dmp.DiffMatchPatch().diffCleanupSemantic(diffResult);
    }

    final currIter = DeltaIterator(currDelta);
    final newIter = DeltaIterator(newDelta);

    diffResult.forEach((component) {
      var length = component.text.length;

      while (length > 0) {
        var opLength = 0;

        switch (component.operation) {
          case dmp.DIFF_INSERT:
            opLength = math.min(newIter.peekLength(), length);
            push(diffDelta, newIter.next(opLength));
            break;

          case dmp.DIFF_DELETE:
            opLength = math.min(length, currIter.peekLength());
            currIter.next(opLength);
            delete(diffDelta, opLength);
            break;

          case dmp.DIFF_EQUAL:
            opLength = math.min(
              math.min(currIter.peekLength(), newIter.peekLength()),
              length,
            );
            final thisOp = currIter.next(opLength);
            final otherOp = newIter.next(opLength);

            if (thisOp.data == otherOp.data) {
              retain(
                diffDelta,
                opLength,
                _diffAttributes(thisOp.attributes, otherOp.attributes),
              );
            } else {
              push(diffDelta, otherOp);
              delete(diffDelta, opLength);
            }

            break;
        }
        length -= opLength;
      }
    });

    trim(diffDelta);

    return diffDelta;
  }

  // Transforms new delta against operations in curr delta. (pure functional).
  // Used for rebasing history states.
  DeltaM transform(
    DeltaM currDelta,
    DeltaM newDelta,
    bool priority,
  ) {
    final deltaRes = DeltaM();
    final currIter = DeltaIterator(currDelta);
    final newIter = DeltaIterator(newDelta);

    while (currIter.hasNext || newIter.hasNext) {
      final newOp = _transformOperation(currIter, newIter, priority);

      if (newOp != null) {
        push(deltaRes, newOp);
      }
    }

    trim(deltaRes);
    return deltaRes;
  }

  // Removes trailing retain operation with empty attributes, if present. (mutates the operations)
  void trim(DeltaM delta) {
    if (delta.isNotEmpty) {
      final last = delta.operations.last;

      if (last.isRetain && last.isPlain) {
        delta.operations.removeLast();
      }
    }
  }

  // Concatenates new delta with curr delta and returns the result. (pure functional)
  // All ops will be chained together regardless of their meaning (retain and delete not applied).
  DeltaM concat(
    DeltaM delta,
    DeltaM newDelta, {
    bool shouldTrimNewLine = false,
  }) {
    final deltaRes = DeltaM.from(delta);

    if (shouldTrimNewLine) {
      trimNewLine(deltaRes);
    }

    if (newDelta.isNotEmpty) {
      // In case first operation of other can be merged with last operation in our list.
      push(deltaRes, newDelta.operations.first);
      deltaRes.operations.addAll(newDelta.operations.sublist(1));
    }

    return deltaRes;
  }

  // Inverts this delta against base. (pure functional)
  // Returns new delta which negates effect of this delta when applied to base.
  // This is an equivalent of "undo" operation on deltas.
  DeltaM invert(DeltaM delta, DeltaM base) {
    final invertedDelta = DeltaM();

    if (base.isEmpty) {
      return invertedDelta;
    }

    var baseIndex = 0;

    for (final op in delta.operations) {
      if (op.isInsert) {
        delete(invertedDelta, op.length!);
      } else if (op.isRetain && op.isPlain) {
        retain(invertedDelta, op.length!);
        baseIndex += op.length!;
      } else if (op.isDelete || (op.isRetain && op.isNotPlain)) {
        final length = op.length!;
        final sliceDelta = slice(base, baseIndex, baseIndex + length);

        sliceDelta.toList().forEach((baseOp) {
          if (op.isDelete) {
            push(invertedDelta, baseOp);
          } else if (op.isRetain && op.isNotPlain) {
            final invertAttr = _invertAttributes(
              op.attributes,
              baseOp.attributes,
            );

            retain(
              invertedDelta,
              baseOp.length!,
              invertAttr.isEmpty ? null : invertAttr,
            );
          }
        });

        baseIndex += length;
      } else {
        throw StateError('Unreachable');
      }
    }

    trim(invertedDelta);

    return invertedDelta;
  }

  // Returns slice of this delta from start index (inclusive) to end (exclusive). (pure functional)
  DeltaM slice(
    DeltaM delta,
    int start, [
    int? end,
  ]) {
    final deltaRes = DeltaM();
    var index = 0;
    final currItr = DeltaIterator(delta);

    final actualEnd = end ?? DeltaIterator.maxLength;

    while (index < actualEnd && currItr.hasNext) {
      OperationM operation;

      if (index < start) {
        operation = currItr.next(start - index);
      } else {
        operation = currItr.next(actualEnd - index);
        push(deltaRes, operation);
      }

      index += operation.length!;
    }

    return deltaRes;
  }

  // Transforms index against this delta. (pure functional)
  // Any "delete" operation before specified index shifts it backward, as well as any "insert" operation shifts it forward.
  // The force argument is used to resolve scenarios when there is an insert operation at the same position as index.
  // If force is set to `true` (default) then position is forced to shift forward, otherwise position stays at the same index.
  // In other words setting force to `false` gives higher priority to the transformed position.
  // Useful to adjust caret or selection positions.
  int transformPosition(
    DeltaM currDelta,
    int index, {
    bool force = true,
  }) {
    final currIter = DeltaIterator(currDelta);
    var offset = 0;

    while (currIter.hasNext && offset <= index) {
      final operation = currIter.next();

      if (operation.isDelete) {
        index -= math.min(operation.length!, index - offset);
        continue;
      } else if (operation.isInsert && (offset < index || force)) {
        index += operation.length!;
      }

      offset += operation.length!;
    }

    return index;
  }

  // Removes trailing '\n' (mutates delta)
  void trimNewLine(DeltaM delta) {
    if (delta.isNotEmpty) {
      final lastOp = delta.operations.last;
      final lastOpData = lastOp.data;

      if (lastOpData is String && lastOpData.endsWith('\n')) {
        delta.operations.removeLast();

        if (lastOpData.length > 1) {
          insert(
            delta,
            lastOpData.substring(0, lastOpData.length - 1),
            lastOp.attributes,
          );
        }
      }
    }
  }

  // === QUERIES ===

  // Compares to deltas and checks if the operations are the same by verifying data equality.
  bool equals(List<OperationM> operations, dynamic newDelta) {
    if (identical(this, newDelta)) {
      return true;
    }

    if (newDelta is! DeltaM) {
      return false;
    }

    final typedNewDelta = newDelta;
    const comparator = ListEquality<OperationM>(
      DefaultEquality<OperationM>(),
    );

    return comparator.equals(operations, typedNewDelta.operations);
  }

  // Get diff operation between old text and new text
  DiffM getDiff(
    String oldText,
    String newText,
    int cursorPosition,
  ) {
    var end = oldText.length;
    final deltaLength = newText.length - end;

    for (final limit = math.max(0, cursorPosition - deltaLength); end > limit && oldText[end - 1] == newText[end + deltaLength - 1]; end--) {}

    var start = 0;

    for (final startLimit = cursorPosition - math.max(0, deltaLength); start < startLimit && oldText[start] == newText[start]; start++) {}

    final deleted = (start >= end) ? '' : oldText.substring(start, end);
    final inserted = newText.substring(start, end + deltaLength);

    return DiffM(start, deleted, inserted);
  }

  // TODO Improve documentation
  // As of jan 2023 it's unclear when this posDelta is not 0.
  // Not sure why it's named user.
  // Prev forked comments don't help at all.
  int getPositionDelta(DeltaM userDelta, DeltaM currDelta) {
    if (currDelta.isEmpty) {
      return 0;
    }

    final userItr = DeltaIterator(userDelta);
    final currItr = DeltaIterator(currDelta);
    var diff = 0;

    while (userItr.hasNext || currItr.hasNext) {
      final length = math.min(userItr.peekLength(), currItr.peekLength());
      final userOperation = userItr.next(length);
      final actualOperation = currItr.next(length);

      if (userOperation.length != actualOperation.length) {
        throw 'userOp ${userOperation.length} does not match actualOp '
            '${actualOperation.length}';
      }

      if (userOperation.key == actualOperation.key) {
        continue;
      } else if (userOperation.isInsert && actualOperation.isRetain) {
        diff -= userOperation.length!;
      } else if (userOperation.isDelete && actualOperation.isRetain) {
        diff += userOperation.length!;
      } else if (userOperation.isRetain && actualOperation.isInsert) {
        String? operationTxt = '';

        if (actualOperation.data is String) {
          operationTxt = actualOperation.data as String?;
        }

        if (operationTxt!.startsWith('\n')) {
          continue;
        }

        diff += actualOperation.length!;
      }
    }

    return diff;
  }

  // === JSON ===

  // Creates DeltaM from de-serialized JSON representation.
  // `dataDecoder` can be used to additionally decode the operation's data object.
  // Only applied to insert operations.
  DeltaM fromJson(List jsonOps, {DataDecoder? dataDecoder}) {
    final operations = jsonOps
        .map((operation) => _opUtils.fromJson(
              operation,
              dataDecoder: dataDecoder,
            ))
        .toList();

    return DeltaM(operations);
  }

  // === PRIVATE - OPERATIONS ===

  void _mergeWithTail(DeltaM delta, OperationM operation) {
    assert(delta.isNotEmpty);
    assert(delta.last.key == operation.key);
    assert(operation.data is String && delta.last.data is String);

    final length = operation.length! + delta.last.length!;
    final lastText = delta.last.data as String;
    final opText = operation.data as String;
    final resultText = lastText + opText;
    final index = delta.operations.length;

    delta.operations.replaceRange(
      index - 1,
      index,
      [
        OperationM(
          operation.key,
          length,
          resultText,
          operation.attributes,
        ),
      ],
    );
  }

  // Composes next operation from currIter and newIter. (Pure functional)
  // Returns new operation or `null` if operations from currIter and newIter nullify each other.
  // For instance, for the pair `insert('abc')` and `delete(3)` composition result would be empty string.
  OperationM? _composeOperation(
    DeltaIterator currIter,
    DeltaIterator newIter,
  ) {
    if (newIter.isNextInsert) {
      return newIter.next();
    }

    if (currIter.isNextDelete) {
      return currIter.next();
    }

    final length = math.min(currIter.peekLength(), newIter.peekLength());
    final currOp = currIter.next(length);
    final newOp = newIter.next(length);

    assert(currOp.length == newOp.length);

    if (newOp.isRetain) {
      final attributes = _composeAttributes(
        currOp.attributes,
        newOp.attributes,
        keepNull: currOp.isRetain,
      );

      if (currOp.isRetain) {
        return _opUtils.getRetainOp(currOp.length, attributes);
      } else if (currOp.isInsert) {
        return _opUtils.getInsertOp(currOp.data, attributes);
      } else {
        throw StateError('Unreachable');
      }
    } else {
      assert(newOp.isDelete);

      if (currOp.isRetain) {
        return newOp;
      }

      assert(currOp.isInsert);
    }

    return null;
  }

  // Transforms next operation from newIter against next operation in currIter. (Pure functional)
  // Returns `null` if both operations nullify each other.
  OperationM? _transformOperation(
    DeltaIterator currIter,
    DeltaIterator newIter,
    bool priority,
  ) {
    if (currIter.isNextInsert && (priority || !newIter.isNextInsert)) {
      return _opUtils.getRetainOp(currIter.next().length);
    } else if (newIter.isNextInsert) {
      return newIter.next();
    }

    final length = math.min(currIter.peekLength(), newIter.peekLength());
    final currOp = currIter.next(length);
    final newOp = newIter.next(length);

    assert(currOp.length == newOp.length);

    // At this point only delete and retain operations are possible.
    if (currOp.isDelete) {
      // newOp is either delete or retain, so they nullify each other.
      return null;
    } else if (newOp.isDelete) {
      return newOp;
    } else {
      // Retain newOp which is either retain or insert.
      return _opUtils.getRetainOp(
        length,
        _transformAttributes(currOp.attributes, newOp.attributes, priority),
      );
    }
  }

  // === ATTRIBUTES ===

  // Transforms two attribute sets. (functional)
  Map<String, dynamic>? _transformAttributes(
    Map<String, dynamic>? a,
    Map<String, dynamic>? b,
    bool priority,
  ) {
    if (a == null) {
      return b;
    }

    if (b == null) {
      return null;
    }

    if (!priority) {
      return b;
    }

    final attrs = b.keys.fold<Map<String, dynamic>>({}, (attributes, key) {
      if (!a.containsKey(key)) {
        attributes[key] = b[key];
      }

      return attributes;
    });

    return attrs.isEmpty ? null : attrs;
  }

  // Composes two attribute sets. (pure functional)
  Map<String, dynamic>? _composeAttributes(
    Map<String, dynamic>? a,
    Map<String, dynamic>? b, {
    bool keepNull = false,
  }) {
    a ??= const {};
    b ??= const {};

    final newAttrs = Map<String, dynamic>.from(a)..addAll(b);
    final keys = newAttrs.keys.toList(growable: false);

    if (!keepNull) {
      for (final key in keys) {
        if (newAttrs[key] == null) newAttrs.remove(key);
      }
    }

    return newAttrs.isEmpty ? null : newAttrs;
  }

  // Get anti-attr result base on base (pure functional)
  Map<String, dynamic> _invertAttributes(
    Map<String, dynamic>? attr,
    Map<String, dynamic>? base,
  ) {
    attr ??= const {};
    base ??= const {};

    final baseInverted = base.keys.fold({}, (dynamic memo, key) {
      if (base![key] != attr![key] && attr.containsKey(key)) {
        memo[key] = base[key];
      }

      return memo;
    });

    final inverted = Map<String, dynamic>.from(
      attr.keys.fold(baseInverted, (memo, key) {
        if (base![key] != attr![key] && !base.containsKey(key)) {
          memo[key] = null;
        }

        return memo;
      }),
    );

    return inverted;
  }

  // Returns diff between two attribute sets (pure functional)
  Map<String, dynamic>? _diffAttributes(
    Map<String, dynamic>? a,
    Map<String, dynamic>? b,
  ) {
    final attributes = <String, dynamic>{};
    a ??= const {};
    b ??= const {};

    (a.keys.toList()..addAll(b.keys)).forEach((key) {
      if (a![key] != b![key]) {
        attributes[key] = b.containsKey(key) ? b[key] : null;
      }
    });

    return attributes.keys.isNotEmpty ? attributes : null;
  }
}
