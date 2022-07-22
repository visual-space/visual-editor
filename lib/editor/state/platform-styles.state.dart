import '../models/platform-dependent-styles.model.dart';

class PlatformStylesState {
  late PlatformDependentStylesM _styles;

  PlatformDependentStylesM get styles => _styles;

  void setPlatformStyles(PlatformDependentStylesM styles) {
    _styles = styles;
  }
}
