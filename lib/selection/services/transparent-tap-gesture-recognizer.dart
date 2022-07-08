import 'package:flutter/gestures.dart';

// A TapGestureRecognizer which allows other GestureRecognizers to win in the GestureArena.
// This means both TransparentTapGestureRecognizer and other GestureRecognizers can handle the same event.
// This enables proper handling of events on both the selection handle and the underlying input,
// since there is significant overlap between the two given the handle's padded hit area.
// For example, the selection handle needs to handle single taps on itself,
// but double taps need to be handled by the underlying input.
class TransparentTapGestureRecognizer extends TapGestureRecognizer {
  TransparentTapGestureRecognizer({
    Object? debugOwner,
  }) : super(debugOwner: debugOwner);

  @override
  void rejectGesture(int pointer) {
    // Accept new gestures that another recognizer has already won.
    // Specifically, this needs to accept taps on the text selection handle on
    // behalf of the text field in order to handle double tap to select.
    // It must not accept other gestures like longpresses and drags that end outside of the text field.
    if (state == GestureRecognizerState.ready) {
      acceptGesture(pointer);
    } else {
      super.rejectGesture(pointer);
    }
  }
}
