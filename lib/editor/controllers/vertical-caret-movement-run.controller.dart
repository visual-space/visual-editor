import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../widgets/editor-textarea-renderer.dart';

// Handles the movement of the caret up and down the document.
// TODO Currently the motion is completely broken. Needs review (check if Quill has the same issue).
class VerticalCaretMovementRunController implements Iterator<TextPosition> {
  VerticalCaretMovementRunController(
    this._renderer,
    this._currentTextPosition,
  );

  TextPosition _currentTextPosition;

  final EditorTextAreaRenderer _renderer;

  @override
  TextPosition get current {
    return _currentTextPosition;
  }

  @override
  bool moveNext() {
    _currentTextPosition = _renderer.getTextPositionBelow(_currentTextPosition);
    return true;
  }

  bool movePrevious() {
    _currentTextPosition = _renderer.getTextPositionAbove(_currentTextPosition);
    return true;
  }
}
