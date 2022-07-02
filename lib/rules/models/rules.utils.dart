import 'package:tuple/tuple.dart';

import '../../documents/controllers/delta.iterator.dart';
import '../../documents/models/delta/operation.model.dart';

Tuple2<OperationM?, int?> getNextNewLine(DeltaIterator iterator) {
  OperationM op;

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
