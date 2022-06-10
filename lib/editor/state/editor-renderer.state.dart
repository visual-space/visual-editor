import '../widgets/editor-renderer.dart';

class EditorRendererState {
  factory EditorRendererState() => _instance;
  static final _instance = EditorRendererState._privateConstructor();

  EditorRendererState._privateConstructor();

  late EditorRenderer _renderer;

  EditorRenderer get renderer => _renderer;

  void setRenderer(EditorRenderer renderer) => _renderer = renderer;
}
