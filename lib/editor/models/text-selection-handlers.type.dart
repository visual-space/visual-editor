import 'package:flutter/material.dart';

// +++ DELETE
// Signature for the callback that reports when the user changes the selection (including the cursor location).
// Used by [RenderEditor.onSelectionChanged].
typedef TextSelectionChangedHandler = void Function(
  TextSelection selection,
  SelectionChangedCause cause,
);

// +++ DELETE
// Signature for the callback that reports when a selection action is actually completed and ratified.
// Completion is defined as when the user input has concluded for an entire selection action.
// For simple taps and keyboard input events that change the selection,
// this callback is invoked immediately following the TextSelectionChangedHandler.
// For long taps, the selection is considered complete at the up event of a long tap.
// For drag selections, the selection completes once the drag/pan event ends or is interrupted.
// Used by [RenderEditor.onSelectionCompleted].
typedef TextSelectionCompletedHandler = void Function();
