import '../../documents/models/document.model.dart';

class DocumentState {
  factory DocumentState() => _instance;
  static final _instance = DocumentState._privateConstructor();

  DocumentState._privateConstructor();

  DocumentM _document = DocumentM();

  DocumentM get document => _document;

  void setDocument(DocumentM document) {
    _document = document;
  }
}
