// Used for undo/ redo operations
class RevertOperationM {
  final bool applyChanges;
  final int? offset;

  RevertOperationM(
    this.applyChanges,
    this.offset,
  );
}
