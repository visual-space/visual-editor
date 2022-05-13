import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../widgets/editor-renderer.dart';

// +++ DOC WHY
class QuillVerticalCaretMovementRun
    extends BidirectionalIterator<TextPosition> {
  QuillVerticalCaretMovementRun(
    this._editor,
    this._currentTextPosition,
  );

  TextPosition _currentTextPosition;

  final RenderEditor _editor;

  @override
  TextPosition get current {
    return _currentTextPosition;
  }

  @override
  bool moveNext() {
    _currentTextPosition = _editor.getTextPositionBelow(_currentTextPosition);
    return true;
  }

  @override
  bool movePrevious() {
    _currentTextPosition = _editor.getTextPositionAbove(_currentTextPosition);
    return true;
  }
}
