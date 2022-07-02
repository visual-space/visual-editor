import 'dart:ui';

import '../../shared/state/editor.state.dart';

// The corner radius of the floating cursor in pixels.
const Radius _kFloatingCaretRadius = Radius.circular(1);

// Floating painter responsible for painting the floating cursor when floating mode is activated
class FloatingCursorPainter {
  Rect? floatingCursorRect;

  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  void setState(EditorState state) {
    _state = state;
  }

  FloatingCursorPainter({
    required this.floatingCursorRect,
    required EditorState state,
  }) {
    setState(state);
  }

  final Paint floatingCursorPaint = Paint();

  void paint(Canvas canvas) {
    final floatingCursorRect = this.floatingCursorRect;
    final floatingCursorColor =
        _state.refs.cursorController.style.color.withOpacity(0.75);

    // Fail safe
    if (floatingCursorRect == null) return;

    canvas.drawRRect(
      RRect.fromRectAndRadius(floatingCursorRect, _kFloatingCaretRadius),
      floatingCursorPaint..color = floatingCursorColor,
    );
  }
}
