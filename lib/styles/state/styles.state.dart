import '../../document/services/nodes/styles.utils.dart';
import '../../visual-editor.dart';

final _stylesUtils = StylesUtils();

class StylesState {

  // === EDITOR STYLES ===

  late EditorStylesM _styles;
  var _initialised = false;

  EditorStylesM get styles => _styles;

  bool get isInitialised => _initialised;

  void setStyles(EditorStylesM styles) {
    _initialised = true;
    _styles = styles;
  }

  // === TOGGLED STYLES ===

  // Stores styles attributes that got toggled by the tap of a button while the pointer is placed between characters.
  // This means we have no way of inserting in the delta document a style since there's no character available to carry the style attribute.
  // However we can attempt to temporarily store the styles in this property until the user starts typing new letters.
  // It gets reset after each format action within the document.
  StyleM toggledStyle = StyleM();

  void updateToggledStyle(AttributeM attribute) {
    toggledStyle = _stylesUtils.put(toggledStyle, attribute);
  }
}
