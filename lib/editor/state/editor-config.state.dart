import '../models/editor-cfg.model.dart';

// These are the settings used by the client app to instantiate a Visual Editor.
class EditorConfigState {
  EditorConfigM _config = const EditorConfigM();

  EditorConfigM get config => _config;

  void setEditorConfig(EditorConfigM config) => _config = config;
}
