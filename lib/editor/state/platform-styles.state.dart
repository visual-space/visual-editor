import '../models/platform-dependent-styles.model.dart';

class PlatformStylesState {
  factory PlatformStylesState() => _instance;
  static final _instance = PlatformStylesState._privateConstructor();

  PlatformStylesState._privateConstructor();

  PlatformDependentStylesM? _styles;

  PlatformDependentStylesM? get styles => _styles;

  void setPlatformStyles(PlatformDependentStylesM? styles) => _styles = styles;
}
