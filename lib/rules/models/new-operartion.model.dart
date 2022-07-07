import '../../documents/models/delta/operation.model.dart';

class NewOperationM {
  final OperationM? operation;
  final int? offset;

  NewOperationM(
    this.operation,
    this.offset,
  );
}
