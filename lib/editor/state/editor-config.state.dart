import '../models/editor-cfg.model.dart';

class EditorConfigState {
  factory EditorConfigState() => _instance;
  static final _instance = EditorConfigState._privateConstructor();

  EditorConfigState._privateConstructor();

  EditorConfigM _config = const EditorConfigM();

  EditorConfigM get config => _config;

  void setEditorConfig(EditorConfigM config) => _config = config;
}
