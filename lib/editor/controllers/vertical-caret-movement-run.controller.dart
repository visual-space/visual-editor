import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../widgets/editor-renderer-inner.dart';

class VerticalCaretMovementRunController
    extends BidirectionalIterator<TextPosition> {
  VerticalCaretMovementRunController(
    this._renderer,
    this._currentTextPosition,
  );

  TextPosition _currentTextPosition;

  final EditorRendererInner _renderer;

  @override
  TextPosition get current {
    return _currentTextPosition;
  }

  @override
  bool moveNext() {
    _currentTextPosition = _renderer.getTextPositionBelow(_currentTextPosition);
    return true;
  }

  @override
  bool movePrevious() {
    _currentTextPosition = _renderer.getTextPositionAbove(_currentTextPosition);
    return true;
  }
}
