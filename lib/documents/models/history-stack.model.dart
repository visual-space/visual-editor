import 'delta/delta.model.dart';

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
