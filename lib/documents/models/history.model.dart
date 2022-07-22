import 'change-source.enum.dart';
import 'delta/delta-changes.model.dart';
import 'delta/delta.model.dart';
import 'delta/operation.model.dart';
import 'document.model.dart';
import 'history-stack.model.dart';
import 'nodes/revert-operations.model.dart';

class HistoryM {
  HistoryM({
    this.ignoreChange = false,
    this.interval = 400,
    this.maxStack = 100,
    this.userOnly = false,
    this.lastRecorded = 0,
  });

  final HistoryStackM stack = HistoryStackM.empty();

  bool get hasUndo => stack.undo.isNotEmpty;

  bool get hasRedo => stack.redo.isNotEmpty;

  // Used for disabling redo or undo function
  bool ignoreChange;

  int lastRecorded;

  // Collaborative editing's conditions should be true
  final bool userOnly;

  // Max operation count for undo
  final int maxStack;

  // Record delay
  final int interval;

  void handleDocChange(DeltaChangeM change) {
    if (ignoreChange) return;
    if (!userOnly || change.source == ChangeSource.LOCAL) {
      record(change.changes, change.initialState);
    } else {
      transform(change.initialState);
    }
  }

  void clear() {
    stack.clear();
  }

  void record(DeltaM change, DeltaM before) {
    if (change.isEmpty) return;
    stack.redo.clear();
    var undoDelta = change.invert(before);
    final timeStamp = DateTime.now().millisecondsSinceEpoch;

    if (lastRecorded + interval > timeStamp && stack.undo.isNotEmpty) {
      final lastDelta = stack.undo.removeLast();
      undoDelta = undoDelta.compose(lastDelta);
    } else {
      lastRecorded = timeStamp;
    }

    if (undoDelta.isEmpty) return;
    stack.undo.add(undoDelta);

    if (stack.undo.length > maxStack) {
      stack.undo.removeAt(0);
    }
  }

  //
  //It will override pre local undo delta,replaced by remote change
  //
  void transform(DeltaM delta) {
    transformStack(stack.undo, delta);
    transformStack(stack.redo, delta);
  }

  void transformStack(List<DeltaM> stack, DeltaM delta) {
    for (var i = stack.length - 1; i >= 0; i -= 1) {
      final oldDelta = stack[i];
      stack[i] = delta.transform(oldDelta, true);
      delta = oldDelta.transform(delta, false);

      if (stack[i].length == 0) {
        stack.removeAt(i);
      }
    }
  }

  RevertOperationM _change(
    DocumentM doc,
    List<DeltaM> source,
    List<DeltaM> dest,
  ) {
    if (source.isEmpty) {
      return RevertOperationM(false, 0);
    }

    final delta = source.removeLast();
    // look for insert or delete
    int? len = 0;
    final operations = delta.toList();

    for (var i = 0; i < operations.length; i++) {
      if (operations[i].key == OperationM.insertKey) {
        len = operations[i].length;
      } else if (operations[i].key == OperationM.deleteKey) {
        len = operations[i].length! * -1;
      }
    }
    final base = DeltaM.from(doc.toDelta());
    final inverseDelta = delta.invert(base);
    dest.add(inverseDelta);
    lastRecorded = 0;
    ignoreChange = true;
    doc.compose(delta, ChangeSource.LOCAL);
    ignoreChange = false;

    return RevertOperationM(true, len);
  }

  RevertOperationM undo(DocumentM doc) {
    return _change(doc, stack.undo, stack.redo);
  }

  RevertOperationM redo(DocumentM doc) {
    return _change(doc, stack.redo, stack.undo);
  }
}
