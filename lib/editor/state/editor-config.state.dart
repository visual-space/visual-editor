import '../models/editor-cfg.model.dart';

class EditorConfigState {
  factory EditorConfigState() => _instance;
  static final _instance = EditorConfigState._privateConstructor();

  EditorConfigState._privateConstructor();

  EditorCfgM _config = const EditorCfgM();

  EditorCfgM get config => _config;

  void setEditorConfig(EditorCfgM config) => _config = config;
}
