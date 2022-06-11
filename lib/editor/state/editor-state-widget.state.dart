import '../widgets/visual-editor.dart';

class EditorStateWidgetState {
  factory EditorStateWidgetState() => _instance;
  static final _instance = EditorStateWidgetState._privateConstructor();

  EditorStateWidgetState._privateConstructor();

  late VisualEditorState _editor;

  VisualEditorState get editor => _editor;

  void setEditorState(VisualEditorState editor) => _editor = editor;
}
