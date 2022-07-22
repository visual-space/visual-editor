import '../../visual-editor.dart';

class StylesState {
  late EditorStylesM _styles;
  var _initialised = false;

  EditorStylesM get styles => _styles;

  bool get isInitialised => _initialised;

  void setStyles(EditorStylesM styles) {
    _initialised = true;
    _styles = styles;
  }
}
