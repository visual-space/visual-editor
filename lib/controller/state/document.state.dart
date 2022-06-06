import 'dart:async';

import '../../documents/models/document.dart';

class DocumentState {
  factory DocumentState() => _instance;
  static final _instance = DocumentState._privateConstructor();

  DocumentState._privateConstructor();

  final _document$ = StreamController<Document>.broadcast();
  Document _document = Document();

  Stream<Document> get document$ => _document$.stream;

  Document get document => _document;

  void setDocument(Document document) {
    _document = document;
    _document$.sink.add(document);
  }
}
