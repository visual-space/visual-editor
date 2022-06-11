import 'dart:async';

import '../../documents/models/document.model.dart';

class DocumentState {
  factory DocumentState() => _instance;
  static final _instance = DocumentState._privateConstructor();

  DocumentState._privateConstructor();

  final _document$ = StreamController<DocumentM>.broadcast();
  DocumentM _document = DocumentM();

  Stream<DocumentM> get document$ => _document$.stream;

  DocumentM get document => _document;

  void setDocument(DocumentM document) {
    _document = document;
    _document$.sink.add(document);
  }
}
