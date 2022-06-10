import '../widgets/raw-editor.dart';

// +++ DELETE - not needed
// (!) INFO
// Here we are breaking the naming conventions a bit.
// Our goal is to store a reference to the state class of the stateful RawEditor.
// By applying the existing conventions the name should be RawEditorStateState.
// However this could be a source of great confusion.
// Therefore here in this place we made an exception and we are going to name it RawEditorWidgetState.
// This name enforces the real intent behind this class.
class RawEditorWidgetState {
  factory RawEditorWidgetState() => _instance;
  static final _instance = RawEditorWidgetState._privateConstructor();

  RawEditorWidgetState._privateConstructor();

  late RawEditor _editor;

  RawEditor get editor => _editor;

  void setRawEditor(RawEditor editor) => _editor = editor;
}
