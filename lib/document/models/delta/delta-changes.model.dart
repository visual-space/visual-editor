import '../../../visual-editor.dart';
import '../history/change-source.enum.dart';
import 'delta.model.dart';

// Used when a document is modified
class DocAndChangeM {
  final DeltaM docDelta;
  final DeltaM changes;
  final ChangeSource source;

  DocAndChangeM(
    this.docDelta,
    this.changes,
    this.source,
  );
}
