import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../services/text-selection.service.dart';
import '../services/transparen-tap-gesture-recognizer.dart';

// Multiple callbacks can be called for one sequence of input gesture.
// A gesture detector to respond to non-exclusive event chains for a text field.
// An ordinary GestureDetector configured to handle events like tap and
// double tap will only recognize one or the other.
// This widget detects both:
// - first the tap and then,
// - if another tap down occurs within a time limit, the double tap.
// See also:
//  * TextField, a Material text field which uses this gesture detector.
//  * CupertinoTextField, a Cupertino text field which uses this gesture detector.
class TextSelectionGestures extends StatefulWidget {
  final HitTestBehavior? behavior;
  final Widget child;

  const TextSelectionGestures({
    required this.child,
    required this.behavior,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TextSelectionGesturesState();
}

class _TextSelectionGesturesState extends State<TextSelectionGestures> {
  final _textSelectionService = TextSelectionService();

  // Counts down for a short duration after a previous tap. Null otherwise.
  Timer? _doubleTapTimer;
  Offset? _lastTapOffset;

  // True if a second tap down of a double tap is detected. Used to discard subsequent tap up / tap hold of the same tap.
  bool _isDoubleTap = false;

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    _dragUpdateThrottleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
        onHover: _handleHover,
        child: RawGestureDetector(
          gestures: _setupGestures(),
          excludeFromSemantics: true,
          behavior: widget.behavior,
          child: widget.child,
        ),
      );

  Map<Type, GestureRecognizerFactory<GestureRecognizer>> _setupGestures() {
    final gestures = <Type, GestureRecognizerFactory>{};

    // Use TransparentTapGestureRecognizer so that TextSelectionGestureDetector can receive
    // the same tap events that a selection handle placed visually on top of it also receives.
    gestures[TransparentTapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<TransparentTapGestureRecognizer>(
      () => TransparentTapGestureRecognizer(debugOwner: this),
      (instance) {
        instance
          ..onTapDown = _handleTapDown
          ..onTapUp = _handleTapUp
          ..onTapCancel = _handleTapCancel;
      },
    );

    gestures[LongPressGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
      () => LongPressGestureRecognizer(
        debugOwner: this,
        supportedDevices: <PointerDeviceKind>{PointerDeviceKind.touch},
      ),
      (instance) {
        instance
          ..onLongPressStart = _handleLongPressStart
          ..onLongPressMoveUpdate = _handleLongPressMoveUpdate
          ..onLongPressEnd = _handleLongPressEnd;
      },
    );

    gestures[HorizontalDragGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
      () => HorizontalDragGestureRecognizer(
        debugOwner: this,
        supportedDevices: <PointerDeviceKind>{PointerDeviceKind.mouse},
      ),
      (instance) {
        // Text selection should start from the position of the first pointer down event.
        instance
          ..dragStartBehavior = DragStartBehavior.down
          ..onStart = _handleDragStart
          ..onUpdate = _handleDragUpdate
          ..onEnd = _handleDragEnd;
      },
    );

    gestures[ForcePressGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<ForcePressGestureRecognizer>(
      () => ForcePressGestureRecognizer(debugOwner: this),
      (instance) {
        instance
          ..onStart = _forcePressStarted
          ..onEnd = _forcePressEnded;
      },
    );
    return gestures;
  }

  void _handleHover(PointerHoverEvent event) {
    _textSelectionService.onHover(event);
  }

  // The down handler is force-run on success of a single tap and optimistically run before a long press success.
  void _handleTapDown(TapDownDetails details) {
    _textSelectionService.onTapDown(details);

    // This isn't detected as a double tap gesture in the gesture recognizer
    // because it's 2 single taps, each of which may do different things
    // depending on whether it's a single tap, the first tap of a double tap,
    // the second tap held down, a clean double tap etc.
    if (_doubleTapTimer != null &&
        _isWithinDoubleTapTolerance(details.globalPosition)) {
      // If there was already a previous tap, the second down hold/tap is a double tap down.
      _textSelectionService.onDoubleTapDown(details);
      _doubleTapTimer!.cancel();
      _doubleTapTimeout();
      _isDoubleTap = true;
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isDoubleTap) {
      _textSelectionService.onSingleTapUp(details);
      _lastTapOffset = details.globalPosition;
      _doubleTapTimer = Timer(kDoubleTapTimeout, _doubleTapTimeout);
    }

    _isDoubleTap = false;
  }

  void _handleTapCancel() {
    _textSelectionService.onSingleTapCancel();
  }

  DragStartDetails? _lastDragStartDetails;
  DragUpdateDetails? _lastDragUpdateDetails;
  Timer? _dragUpdateThrottleTimer;

  void _handleDragStart(DragStartDetails details) {
    assert(_lastDragStartDetails == null);
    _lastDragStartDetails = details;
    _textSelectionService.onDragSelectionStart(details);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _lastDragUpdateDetails = details;
    _dragUpdateThrottleTimer ??= Timer(
      const Duration(milliseconds: 50),
      _handleDragUpdateThrottled,
    );
  }

  // Drag updates are being throttled to avoid excessive text layouts in text fields.
  // The frequency of invocations is controlled by the constant [_kDragSelectionUpdateThrottle].
  // Once the drag gesture ends, any pending drag update will be fired immediately. See [_handleDragEnd].
  void _handleDragUpdateThrottled() {
    assert(_lastDragStartDetails != null);
    assert(_lastDragUpdateDetails != null);

    _textSelectionService.onDragSelectionUpdate(
      _lastDragStartDetails!,
      _lastDragUpdateDetails!,
    );

    _dragUpdateThrottleTimer = null;
    _lastDragUpdateDetails = null;
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(_lastDragStartDetails != null);

    if (_dragUpdateThrottleTimer != null) {
      // If there's already an update scheduled, trigger it immediately and cancel the timer.
      _dragUpdateThrottleTimer!.cancel();
      _handleDragUpdateThrottled();
    }

    _textSelectionService.onDragSelectionEnd(details);

    _dragUpdateThrottleTimer = null;
    _lastDragStartDetails = null;
    _lastDragUpdateDetails = null;
  }

  void _forcePressStarted(ForcePressDetails details) {
    _doubleTapTimer?.cancel();
    _doubleTapTimer = null;

    _textSelectionService.onForcePressStart(details);
  }

  void _forcePressEnded(ForcePressDetails details) {
    _textSelectionService.onForcePressEnd(details);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!_isDoubleTap) {
      _textSelectionService.onSingleLongTapStart(details);
    }
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isDoubleTap) {
      _textSelectionService.onSingleLongTapMoveUpdate(details);
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!_isDoubleTap) {
      _textSelectionService.onSingleLongTapEnd(details);
    }

    _isDoubleTap = false;
  }

  void _doubleTapTimeout() {
    _doubleTapTimer = null;
    _lastTapOffset = null;
  }

  bool _isWithinDoubleTapTolerance(Offset secondTapOffset) {
    if (_lastTapOffset == null) {
      return false;
    }

    return (secondTapOffset - _lastTapOffset!).distance <= kDoubleTapSlop;
  }
}
