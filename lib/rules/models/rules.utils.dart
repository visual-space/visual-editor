import 'package:tuple/tuple.dart';

import '../../../delta/controllers/delta-iterator.controller.dart';
import '../../../delta/models/operation.model.dart';

Tuple2<Operation?, int?> getNextNewLine(DeltaIterator iterator) {
  Operation op;

  for (var skipped = 0; iterator.hasNext; skipped += op.length!) {
    op = iterator.next();
    final lineBreak =
        (op.data is String ? op.data as String? : '')!.indexOf('\n');

    if (lineBreak >= 0) {
      return Tuple2(op, skipped);
    }
  }

  return const Tuple2(null, null);
}
