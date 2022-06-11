import 'package:flutter/cupertino.dart';

// The padding applied to text field. +++ REVIEW
// Used to determine the bounds when moving the floating cursor.
const EdgeInsets floatingCursorAddedMargin = EdgeInsets.fromLTRB(4, 4, 4, 5);

// The additional size on the x and y axis with which to expand the prototype
// cursor to render the floating cursor in pixels.
const EdgeInsets floatingCaretSizeIncrease = EdgeInsets.symmetric(
  horizontal: 0.5,
  vertical: 1,
);
