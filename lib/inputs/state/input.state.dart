import 'package:flutter/services.dart';

class InputState {
  TextInputConnection? textInputConnection;

  // Caches the prev plain text value received from the remote input.
  // It will be used to compare with the new value and retrieve
  // the diff and then patch it to to the document.
  var prevPlainText = TextEditingValue();

  // Whether to show the selection buttons.
  // It is based on the signal source when a onTapDown is called.
  // Will return true if current onTapDown event is triggered by a touch or a stylus.
  var shouldShowSelectionToolbar = true;
}
