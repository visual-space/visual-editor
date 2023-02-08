import 'package:flutter/material.dart';

import '../../shared/models/selection-rectangles.model.dart';

typedef TapDownCallback = Function(
  TapDownDetails details,
  TextPosition Function(Offset offset),
);

typedef TapUpCallback = Function(
  TapUpDetails details,
  TextPosition Function(Offset offset),
);

typedef SingleLongTapStartCallback = bool Function(
  LongPressStartDetails details,
  TextPosition Function(Offset offset),
);

typedef SingleLongTapMoveCallback = bool Function(
  LongPressMoveUpdateDetails details,
  TextPosition Function(Offset offset),
);

typedef SingleLongTapCallback = bool Function(
  LongPressEndDetails details,
  TextPosition Function(Offset offset),
);

// Return false to ignore the event.
typedef ReplaceTextCallback = bool Function(
  int index,
  int len,
  Object? data,
);

typedef DeleteCallback = void Function(
  int cursorPosition,
  bool forward,
);

typedef SelectionCompleteCallback = void Function(
  List<SelectionRectanglesM?> rectanglesByLines,
);

typedef OnSelectionChangedCallback = void Function(
  TextSelection selection,
);
