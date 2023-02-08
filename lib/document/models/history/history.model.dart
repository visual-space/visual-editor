import 'history-stack.model.dart';

// Stores 2 stacks of change deltas: undo and redo (can store also coop editing states).
// The document model uses these stacks to record the history of edits.
// Edits can be recorded at a regular interval (to save memory space).
// A max amount of history states can be saved (to save memory space).
// User only means that we are in coop editing mode.
// In coop mode the history stacks can be rebased with the remote document.
// Each document has it's own history (we don't keep one central history state in state store).
// This means that multiple documents can be live at once, each one with it's own history state.
// TODO Several props are currently not provided any values from the caller code (ignoreChange, userOnly, interval).
class HistoryM {
  final HistoryStackM stack = HistoryStackM.empty();

  // Used for disabling redo or undo function
  bool ignoreChange;

  int lastRecorded;

  // Collaborative editing's conditions should be true
  final bool userOnly;

  // Max operation count for undo
  final int maxStack;

  // Record delay, how many ms to wait until registering a new history state.
  final int interval;

  HistoryM({
    this.ignoreChange = false,
    this.interval = 400,
    this.maxStack = 100,
    this.userOnly = false,
    this.lastRecorded = 0,
  });

  bool get hasUndo {
    return stack.undo.isNotEmpty;
  }

  bool get hasRedo {
    return stack.redo.isNotEmpty;
  }
}
