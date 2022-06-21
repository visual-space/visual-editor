import '../../main.dart';

class EditorWidgetState {
  factory EditorWidgetState() => _instance;
  static final _instance = EditorWidgetState._privateConstructor();

  EditorWidgetState._privateConstructor();

  late VisualEditor _editor;

  VisualEditor get editor => _editor;

  void setEditor(VisualEditor editor) => _editor = editor;
}
