import '../widgets/raw-editor.dart';

// (!) INFO
// Here we are breaking the naming conventions a bit.
// Our goal is to store a reference to the state class of the stateful RawEditor.
// By applying the existing conventions the name should be RawEditorStateState.
// However this could be a source of great confusion.
// Therefore here in this place we made an exception and we are going to name it RawEditorSWidgetState.
// SWidget is used to indicate the is the State class of the RawEditor stateful widget.
// This name enforces the real intent behind this class.
class RawEditorSWidgetState {
  factory RawEditorSWidgetState() => _instance;
  static final _instance = RawEditorSWidgetState._privateConstructor();

  RawEditorSWidgetState._privateConstructor();

  late RawEditorState _editor;

  RawEditorState get editor => _editor;

  void setRawEditorState(RawEditorState editor) => _editor = editor;
}
