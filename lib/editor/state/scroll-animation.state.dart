// This is a workaround for checkbox tapping issue
// https://github.com/singerdmx/flutter-quill/issues/619
// We cannot treat {"list": "checked"} and {"list": "unchecked"} as block of the same style.
// This causes controller.selection to go to offset 0.
class ScrollAnimationState {
  late bool _disabled;

  bool get disabled => _disabled;

  void disableAnimationOnce(bool disable) => _disabled = disable;
}
