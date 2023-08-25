import '../models/delta-doc.model.dart';
import '../models/delta/delta-changes.model.dart';
import '../models/delta/delta.model.dart';
import '../models/delta/operations.enum.dart';
import '../models/history/change-source.enum.dart';
import '../models/history/history.model.dart';
import '../models/nodes/revert-operations.model.dart';
import '../services/delta.utils.dart';

// The document model uses these stacks to record the history of edits.
// Edits can be recorded at a regular interval (to save memory space).
// A max amount of history states can be saved (to save memory space).
// User only means that we are in coop editing mode.
// In coop mode the history stacks can be rebased with the remote document.
class HistoryController {
  final DeltaDocM _document;
  final Function(DeltaM deltaRes, int? length, bool emitEvent)?
      _composeCacheSelectionAndRunBuild;
  final _du = DeltaUtils();

  HistoryController(
    this._document,
    this._composeCacheSelectionAndRunBuild,
  );

  // Supports coop editing.
  // If userOnly is enabled we record only local changes.
  // Otherwise we record both remote and local changes.
  // When storing remote changes the history class can undo redo the local changes
  // while maintaining the remote changes.
  void updateHistoryStacks(DocAndChangeM change) {
    if (_history.ignoreChange) {
      return;
    }

    // TODO Use from history settings from editor config (currently client code can't change this setup)
    if (!_history.userOnly || change.source == ChangeSource.LOCAL) {
      _record(change.changes, change.docDelta);
    } else {
      _transform(change.docDelta);
    }
  }

  // Returns back metrics that could be useful to client code for
  RevertOperationM undo([bool emitEvent = true]) {
    final revertOp = _restoreDocumentAndUpdateHistoryStacks(
      _document,
      _history.stack.undo,
      _history.stack.redo,
      emitEvent,
    );

    return revertOp;
  }

  RevertOperationM redo([bool emitEvent = true]) {
    final revertOp = _restoreDocumentAndUpdateHistoryStacks(
        _document, _history.stack.redo, _history.stack.undo, emitEvent);

    return revertOp;
  }

  bool get hasUndo {
    return _document.history.hasUndo;
  }

  bool get hasRedo {
    return _document.history.hasRedo;
  }

  void clearHistory() {
    _history.stack.clear();
  }

  // === PRIVATE ===

  HistoryM get _history {
    return _document.history;
  }

  // Records changes (undo, redo changes) at regular intervals.
  // Clears the tail of the stack if history levels limit is reached.
  void _record(DeltaM change, DeltaM before) {
    if (change.isEmpty) {
      return;
    }

    _history.stack.redo.clear();
    var undoDelta = _du.invert(change, before);
    final timeStamp = DateTime.now().millisecondsSinceEpoch;

    if (_history.lastRecorded + _history.interval > timeStamp &&
        _history.stack.undo.isNotEmpty) {
      final lastDelta = _history.stack.undo.removeLast();
      undoDelta = _du.compose(undoDelta, lastDelta);
    } else {
      _history.lastRecorded = timeStamp;
    }

    if (undoDelta.isEmpty) {
      return;
    }

    _history.stack.undo.add(undoDelta);

    if (_history.stack.undo.length > _history.maxStack) {
      _history.stack.undo.removeAt(0);
    }
  }

  // Rebase history stacks with the latest version of the live document.
  void _transform(DeltaM remoteDelta) {
    _transformStack(_history.stack.undo, remoteDelta);
    _transformStack(_history.stack.redo, remoteDelta);
  }

  // Transforms the entire stack to contain the latest state of the remote document.
  // Think of it as git rebase for your current branch.
  void _transformStack(List<DeltaM> stack, DeltaM remoteDelta) {
    for (var i = stack.length - 1; i >= 0; i -= 1) {
      final invertedDelta = stack[i];
      stack[i] = _du.transform(remoteDelta, invertedDelta, true);
      remoteDelta = _du.transform(invertedDelta, remoteDelta, false);

      if (stack[i].length == 0) {
        stack.removeAt(i);
      }
    }
  }

  // Updates the document with the information from the latest state in the history stacks.
  // Updates the history stacks to indicate the current state of the document (older or newer doc state).
  // Depending on the direction, one stack adds a new history and the other stack removes it.
  RevertOperationM _restoreDocumentAndUpdateHistoryStacks(
    DeltaDocM document,
    List<DeltaM> sourceStack,
    List<DeltaM> destinationStack,
    bool emitEvent,
  ) {
    if (sourceStack.isEmpty) {
      return RevertOperationM(false, 0);
    }

    final deltaRes = sourceStack.removeLast();

    // Look for insert or delete
    int? extent = 0;
    final operations = deltaRes.toList();

    for (var i = 0; i < operations.length; i++) {
      if (operations[i].key == INSERT_KEY) {
        extent = operations[i].length;
      } else if (operations[i].key == DELETE_KEY) {
        extent = operations[i].length! * -1;
      }
    }

    // Move to other stack
    final base = DeltaM.from(document.delta);
    final inverseDelta = _du.invert(deltaRes, base);

    destinationStack.add(inverseDelta);

    // Reset timer
    _history.lastRecorded = 0;

    // Apply recovered history state to document
    _history.ignoreChange = true;
    _composeCacheSelectionAndRunBuild?.call(deltaRes, extent, emitEvent);
    _history.ignoreChange = false;

    // Metrics (if needed)
    return RevertOperationM(true, extent);
  }
}
