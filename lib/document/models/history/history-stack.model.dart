import '../delta/delta.model.dart';

// At regular intervals we store a new state of history (a delta that has the diff).
// When the undo() redo() ops are invoked we move states from one stack to the other.
// Obviously if a new change is applied after several undo calls, the redo stack is emptied.
// Remote changes are rebased on the current user changes stacks (for coop editing).
class HistoryStackM {
  HistoryStackM.empty()
      : undo = [],
        redo = [];

  final List<DeltaM> undo;
  final List<DeltaM> redo;

  void clear() {
    undo.clear();
    redo.clear();
  }
}
