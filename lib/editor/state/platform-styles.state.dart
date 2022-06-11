import '../models/platform-dependent-styles.model.dart';

class PlatformStylesState {
  factory PlatformStylesState() => _instance;
  static final _instance = PlatformStylesState._privateConstructor();

  PlatformStylesState._privateConstructor();

  late PlatformDependentStylesM _styles;
  var _initialised = false;

  PlatformDependentStylesM get styles => _styles;
  bool get isInitialised => _initialised;

  void setPlatformStyles(PlatformDependentStylesM styles) {
    _initialised = true;
    _styles = styles;
  }
}
