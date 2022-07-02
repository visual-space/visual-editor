import '../models/document.model.dart';

class DocumentState {
  DocumentM _document = DocumentM();

  DocumentM get document => _document;

  void setDocument(DocumentM document) {
    _document = document;
  }
}
