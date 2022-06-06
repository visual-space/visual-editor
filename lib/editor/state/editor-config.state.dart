import 'dart:async';

import '../models/editor-cfg.model.dart';

class EditorConfigState {
  factory EditorConfigState() => _instance;
  static final _instance = EditorConfigState._privateConstructor();

  EditorConfigState._privateConstructor();

  final _config$ = StreamController<EditorCfgM>.broadcast();
  EditorCfgM _config = const EditorCfgM();

  Stream<EditorCfgM> get config$ => _config$.stream;

  EditorCfgM get config => _config;

  void setEditorConfig(EditorCfgM config) {
    _config = config;
    _config$.sink.add(config);
  }
}
