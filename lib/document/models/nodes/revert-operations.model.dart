// Reports if undo redo made any changes in the history stacks.
// TODO Could be useful for coop editing. Not sure yet how.
class RevertOperationM {
  final bool applyChanges;
  final int? extent;

  RevertOperationM(
    this.applyChanges,
    this.extent,
  );
}
