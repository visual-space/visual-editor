import 'package:flutter/material.dart';

import '../../editor/models/editor-state.model.dart';

// Delegate interface for the [EditorTextSelectionGestureDetectorBuilder].
// The interface is usually implemented by textfield implementations wrapping
// [EditableText], that use a [EditorTextSelectionGestureDetectorBuilder]
// to build a [EditorTextSelectionGestureDetector] for their [EditableText].
// The delegate provides the builder with information about the current state of the textfield.
// Based on these information, the builder adds the correct gesture handlers to the gesture detector.
// See also:
//  * [TextField], which implements this delegate for the Material textfield.
//  * [CupertinoTextField], which implements this delegate for the Cupertino textfield.
abstract class EditorTextSelectionGestureDetectorBuilderDelegate {
  // [GlobalKey] to the [EditableText] for which the
  // [EditorTextSelectionGestureDetectorBuilder] will build
  // a [EditorTextSelectionGestureDetector].
  GlobalKey<EditorState> get editableTextKey;

  // Whether the textfield should respond to force presses.
  bool get forcePressEnabled;

  // Whether the user may select text in the textfield.
  bool get selectionEnabled;
}
