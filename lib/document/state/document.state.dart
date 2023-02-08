import 'dart:async';

import '../models/delta/delta-changes.model.dart';
import '../models/document.model.dart';

// Stores the document as pure data.
// Emits a stream of changes when the documetn is edited
class DocumentState {

  // === DOCUMENT ===

  // Document that is currently used by the controller.
  // Multiple documents can be swapped on the same editor.
  var document = DocumentM();

  // === CHANGES ===

  // Stream of the changes made on the current document.
  final _changes$ = StreamController<DocAndChangeM>.broadcast();

  Stream<DocAndChangeM> get changes$ => _changes$.stream;

  bool get changesStreamIsClosed => _changes$.isClosed;

  void emitChange(DocAndChangeM change) => _changes$.add(change);

  // Flushes out the history of changes.
  // Useful when you want to discard a document and to release the memory.
  void closeChangesStream() {
    _changes$.close();
  }
}
