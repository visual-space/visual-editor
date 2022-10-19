import 'dart:math' as math;
import 'dart:ui';

import '../controllers/delta.iterator.dart';
import '../models/attributes/attributes-aliases.model.dart';
import '../models/attributes/attributes.model.dart';
import '../models/delta/delta.model.dart';
import '../models/delta/diff.model.dart';
import '../models/nodes/node.model.dart';

/* Get diff operation between old text and new text */
DiffM getDiff(
  String oldText,
  String newText,
  int cursorPosition,
) {
  var end = oldText.length;
  final delta = newText.length - end;

  for (final limit = math.max(0, cursorPosition - delta);
      end > limit && oldText[end - 1] == newText[end + delta - 1];
      end--) {}

  var start = 0;

  for (final startLimit = cursorPosition - math.max(0, delta);
      start < startLimit && oldText[start] == newText[start];
      start++) {}

  final deleted = (start >= end) ? '' : oldText.substring(start, end);
  final inserted = newText.substring(start, end + delta);

  return DiffM(start, deleted, inserted);
}

int getPositionDelta(
  DeltaM user,
  DeltaM actual,
) {
  if (actual.isEmpty) {
    return 0;
  }

  final userItr = DeltaIterator(user);
  final actualItr = DeltaIterator(actual);
  var diff = 0;

  while (userItr.hasNext || actualItr.hasNext) {
    final length = math.min(userItr.peekLength(), actualItr.peekLength());
    final userOperation = userItr.next(length);
    final actualOperation = actualItr.next(length);

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

TextDirection getDirectionOfNode(NodeM node) {
  final direction = node.style.attributes[AttributesM.direction.key];

  if (direction == AttributesAliasesM.rtl) {
    return TextDirection.rtl;
  }

  return TextDirection.ltr;
}
