import '../widgets/editor-renderer-inner.dart';

class EditorRendererState {
  factory EditorRendererState() => _instance;
  static final _instance = EditorRendererState._privateConstructor();

  EditorRendererState._privateConstructor();

  late EditorRendererInner _renderer;

  EditorRendererInner get renderer => _renderer;

  void setRenderer(EditorRendererInner renderer) => _renderer = renderer;
}
