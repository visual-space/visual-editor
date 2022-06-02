import 'package:flutter/material.dart';

import '../../editor/models/editor-state.model.dart';

// Delegate interface for the [TextSelectionGesturesBuilder].
// The interface is usually implemented by textfield implementations wrapping
// [VisualEditor], that use a [TextSelectionGesturesBuilder]
// to build a [TextSelectionGestures] for their [VisualEditor].
// The delegate provides the builder with information about the current state of the textfield.
// Based on these information, the builder adds the correct gesture handlers to the gesture detector.
// See also:
//  * [TextField], which implements this delegate for the Material textfield.
//  * [CupertinoTextField], which implements this delegate for the Cupertino textfield.
abstract class TextSelectionGesturesBuilderDelegateM {
  // [GlobalKey] to the [VisualEditor] for which the
  // [TextSelectionGesturesBuilder] will build
  // a [TextSelectionGestures].
  GlobalKey<EditorState> get editableTextKey;

  // Whether the textfield should respond to force presses.
  bool get forcePressEnabled;

  // Whether the user may select text in the textfield.
  bool get selectionEnabled;
}
