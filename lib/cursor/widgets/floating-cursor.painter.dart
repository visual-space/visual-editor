import 'dart:ui';

import '../../shared/state/editor.state.dart';

// The corner radius of the floating cursor in pixels.
const Radius _kFloatingCaretRadius = Radius.circular(1);

// Floating painter responsible for painting the floating cursor when floating mode is activated
class FloatingCursorPainter {
  Rect? floatingCursorRect;
  late EditorState _state;

  FloatingCursorPainter({
    required this.floatingCursorRect,
    required EditorState state,
  }) {
    _cacheStateStore(state);
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

  void _cacheStateStore(EditorState state) {
    _state = state;
  }
}
