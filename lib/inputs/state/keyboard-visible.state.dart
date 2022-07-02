class KeyboardVisibleState {
  bool _keyboardVisible = false;

  bool get isVisible => _keyboardVisible;

  // Emits only when the modifier keys are pressed or released
  void setKeyboardVisible(bool isVisible) {
    _keyboardVisible = isVisible;
  }
}
