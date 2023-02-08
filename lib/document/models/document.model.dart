import '../services/delta.utils.dart';
import '../services/document.utils.dart';
import 'delta/delta.model.dart';
import 'history/history.model.dart';

final _documentUtils = DocumentUtils();
final _du = DeltaUtils();

// Document model contains the raw data representation:
// - DeltaM - List of operations as stored in the json document (insert, delete, retain).
// - HistoryM - Stacks of undo adn redo operations (each doc has it's own history).
// Document models can be initialised empty or from json data or delta models.
// Documents can be edited outside of the editor by a DocumentController class.
// We decided to use this approach to avoid create monster models with excessive data and models in one scope.
// We prefer the pure functional approach for the sake of keeping the models easy to comprehend by new contributors.
// Also another reason to keep the api in a DocumentController class was the simple fact that not many
// developers will be using the document API directly for manipulating the doc in memory.
// Those experienced enough to require such operations will be able to do so using a new instance of the DocumentController.
// The net gain is that we have far easier code to read and comprehend compared to the forked Quill repo.
// And this is what we care the most right now, being highly accessible for new developers
// not slightly more accessible for experienced devs.
// Read editor.md for a full breakdown of the editor architecture.
// @@@ TODO Copy to docs
class DocumentM {
  late DeltaM delta;
  final history = HistoryM();

  DocumentM() {
    delta = DeltaM();
    _du.insert(delta, '\n');
  }

  DocumentM.fromJson(List data) {
    delta = _documentUtils.fromJson(data);
  }
}
