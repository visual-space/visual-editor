import '../../document/controllers/delta.iterator.dart';
import '../../document/models/delta/operation.model.dart';
import 'new-operartion.model.dart';

NewOperationM getNextNewLine(DeltaIterator iterator) {
  OperationM operation;

  for (var skipped = 0; iterator.hasNext; skipped += operation.length!) {
    operation = iterator.next();
    final lineBreak =
        (operation.data is String ? operation.data as String? : '')!
            .indexOf('\n');

    if (lineBreak >= 0) {
      return NewOperationM(operation, skipped);
    }
  }

  return NewOperationM(null, null);
}
