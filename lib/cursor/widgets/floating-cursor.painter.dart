import 'dart:ui';

import '../state/cursor-controller.state.dart';

// The corner radius of the floating cursor in pixels.
const Radius _kFloatingCaretRadius = Radius.circular(1);

// Floating painter responsible for painting the floating cursor when floating mode is activated
class FloatingCursorPainter {
  final _cursorControllerState = CursorControllerState();

  Rect? floatingCursorRect;

  FloatingCursorPainter({required this.floatingCursorRect});

  final Paint floatingCursorPaint = Paint();

  void paint(Canvas canvas) {
    final floatingCursorRect = this.floatingCursorRect;
    final floatingCursorColor =
        _cursorControllerState.controller.style.color.withOpacity(0.75);

    // Fail safe
    if (floatingCursorRect == null) return;

    canvas.drawRRect(
      RRect.fromRectAndRadius(floatingCursorRect, _kFloatingCaretRadius),
      floatingCursorPaint..color = floatingCursorColor,
    );
  }
}
