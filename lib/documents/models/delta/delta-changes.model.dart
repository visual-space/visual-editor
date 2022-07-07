import '../../../visual-editor.dart';
import '../change-source.enum.dart';
import 'delta.model.dart';

// Used when a document is modified
class DeltaChangeM {
  final DeltaM initialState;
  final DeltaM changes;
  final ChangeSource source;

  DeltaChangeM(
    this.initialState,
    this.changes,
    this.source,
  );
}
