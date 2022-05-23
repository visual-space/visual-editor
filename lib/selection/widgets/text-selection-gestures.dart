import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  const TextSelectionGestures({
    required this.child,
    this.onHover,
    this.onTapDown,
    this.onForcePressStart,
    this.onForcePressEnd,
    this.onSingleTapUp,
    this.onSingleTapCancel,
    this.onSingleLongTapStart,
    this.onSingleLongTapMoveUpdate,
    this.onSingleLongTapEnd,
    this.onDoubleTapDown,
    this.onDragSelectionStart,
    this.onDragSelectionUpdate,
    this.onDragSelectionEnd,
    this.behavior,
    Key? key,
  }) : super(key: key);

  final PointerHoverEventListener? onHover;

  // Called for every tap down including every tap down that's part of a double click or a long press,
  // except touches that include enough movement to not qualify as taps (e.g. pans and flings).
  final GestureTapDownCallback? onTapDown;

  // Called when a pointer has tapped down and the force of the pointer has
  // just become greater than ForcePressGestureRecognizer.startPressure.
  final GestureForcePressStartCallback? onForcePressStart;

  // Called when a pointer that had previously triggered onForcePressStart is lifted off the screen.
  final GestureForcePressEndCallback? onForcePressEnd;

  // Called for each distinct tap except for every second tap of a double tap.
  // For example, if the detector was configured with onTapDown and
  // onDoubleTapDown, three quick taps would be recognized as a single tap
  // down, followed by a double tap down, followed by a single tap down.
  final GestureTapUpCallback? onSingleTapUp;

  // Called for each touch that becomes recognized as a gesture that is not a short tap, such as a long tap or drag.
  // It is called at the moment when another gesture from the touch is recognized.
  final GestureTapCancelCallback? onSingleTapCancel;

  // Called for a single long tap that's sustained for longer than kLongPressTimeout but not necessarily lifted.
  // Not called for a double-tap-hold, which calls onDoubleTapDown instead.
  final GestureLongPressStartCallback? onSingleLongTapStart;

  // Called after onSingleLongTapStart when the pointer is dragged.
  final GestureLongPressMoveUpdateCallback? onSingleLongTapMoveUpdate;

  // Called after onSingleLongTapStart when the pointer is lifted.
  final GestureLongPressEndCallback? onSingleLongTapEnd;

  // Called after a momentary hold or a short tap that is close in space and
  // time (within kDoubleTapTimeout) to a previous short tap.
  final GestureTapDownCallback? onDoubleTapDown;

  // Called when a mouse starts dragging to select text.
  final GestureDragStartCallback? onDragSelectionStart;

  // Called repeatedly as a mouse moves while dragging.
  // The frequency of calls is throttled to avoid excessive text layout operations in text fields.
  // The throttling is controlled by the constant _kDragSelectionUpdateThrottle.
  final DragSelectionUpdateCallback? onDragSelectionUpdate;

  // Called when a mouse that was previously dragging is released.
  final GestureDragEndCallback? onDragSelectionEnd;

  // How this gesture detector should behave during hit testing.
  // This defaults to HitTestBehavior.deferToChild.
  final HitTestBehavior? behavior;

  // Child below this widget.
  final Widget child;

  @override
  State<StatefulWidget> createState() => _TextSelectionGesturesState();
}

class _TextSelectionGesturesState extends State<TextSelectionGestures> {
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

  void _handleHover(PointerHoverEvent event) {
    if (widget.onHover != null) {
      widget.onHover!(event);
    }
  }

  // The down handler is force-run on success of a single tap and optimistically run before a long press success.
  void _handleTapDown(TapDownDetails details) {
    if (widget.onTapDown != null) {
      widget.onTapDown!(details);
    }

    // This isn't detected as a double tap gesture in the gesture recognizer
    // because it's 2 single taps, each of which may do different things
    // depending on whether it's a single tap, the first tap of a double tap,
    // the second tap held down, a clean double tap etc.
    if (_doubleTapTimer != null &&
        _isWithinDoubleTapTolerance(details.globalPosition)) {
      // If there was already a previous tap, the second down hold/tap is a double tap down.
      if (widget.onDoubleTapDown != null) {
        widget.onDoubleTapDown!(details);
      }

      _doubleTapTimer!.cancel();
      _doubleTapTimeout();
      _isDoubleTap = true;
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isDoubleTap) {
      if (widget.onSingleTapUp != null) {
        widget.onSingleTapUp!(details);
      }
      _lastTapOffset = details.globalPosition;
      _doubleTapTimer = Timer(kDoubleTapTimeout, _doubleTapTimeout);
    }
    _isDoubleTap = false;
  }

  void _handleTapCancel() {
    if (widget.onSingleTapCancel != null) {
      widget.onSingleTapCancel!();
    }
  }

  DragStartDetails? _lastDragStartDetails;
  DragUpdateDetails? _lastDragUpdateDetails;
  Timer? _dragUpdateThrottleTimer;

  void _handleDragStart(DragStartDetails details) {
    assert(_lastDragStartDetails == null);
    _lastDragStartDetails = details;

    if (widget.onDragSelectionStart != null) {
      widget.onDragSelectionStart!(details);
    }
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
    if (widget.onDragSelectionUpdate != null) {
      widget.onDragSelectionUpdate!(
        _lastDragStartDetails!,
        _lastDragUpdateDetails!,
      );
    }
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
    if (widget.onDragSelectionEnd != null) {
      widget.onDragSelectionEnd!(details);
    }
    _dragUpdateThrottleTimer = null;
    _lastDragStartDetails = null;
    _lastDragUpdateDetails = null;
  }

  void _forcePressStarted(ForcePressDetails details) {
    _doubleTapTimer?.cancel();
    _doubleTapTimer = null;
    if (widget.onForcePressStart != null) {
      widget.onForcePressStart!(details);
    }
  }

  void _forcePressEnded(ForcePressDetails details) {
    if (widget.onForcePressEnd != null) {
      widget.onForcePressEnd!(details);
    }
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!_isDoubleTap && widget.onSingleLongTapStart != null) {
      widget.onSingleLongTapStart!(details);
    }
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isDoubleTap && widget.onSingleLongTapMoveUpdate != null) {
      widget.onSingleLongTapMoveUpdate!(details);
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!_isDoubleTap && widget.onSingleLongTapEnd != null) {
      widget.onSingleLongTapEnd!(details);
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

  @override
  Widget build(BuildContext context) {
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

    if (widget.onSingleLongTapStart != null ||
        widget.onSingleLongTapMoveUpdate != null ||
        widget.onSingleLongTapEnd != null) {
      gestures[LongPressGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
        () => LongPressGestureRecognizer(
            debugOwner: this,
            supportedDevices: <PointerDeviceKind>{PointerDeviceKind.touch}),
        (instance) {
          instance
            ..onLongPressStart = _handleLongPressStart
            ..onLongPressMoveUpdate = _handleLongPressMoveUpdate
            ..onLongPressEnd = _handleLongPressEnd;
        },
      );
    }

    if (widget.onDragSelectionStart != null ||
        widget.onDragSelectionUpdate != null ||
        widget.onDragSelectionEnd != null) {
      gestures[HorizontalDragGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
        () => HorizontalDragGestureRecognizer(
            debugOwner: this,
            supportedDevices: <PointerDeviceKind>{PointerDeviceKind.mouse}),
        (instance) {
          // Text selection should start from the position of the first pointer down event.
          instance
            ..dragStartBehavior = DragStartBehavior.down
            ..onStart = _handleDragStart
            ..onUpdate = _handleDragUpdate
            ..onEnd = _handleDragEnd;
        },
      );
    }

    if (widget.onForcePressStart != null || widget.onForcePressEnd != null) {
      gestures[ForcePressGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<ForcePressGestureRecognizer>(
        () => ForcePressGestureRecognizer(debugOwner: this),
        (instance) {
          instance
            ..onStart =
                widget.onForcePressStart != null ? _forcePressStarted : null
            ..onEnd = widget.onForcePressEnd != null ? _forcePressEnded : null;
        },
      );
    }

    return MouseRegion(
      onHover: _handleHover,
      child: RawGestureDetector(
        gestures: gestures,
        excludeFromSemantics: true,
        behavior: widget.behavior,
        child: widget.child,
      ),
    );
  }
}
