import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../highlights/services/highlights.service.dart';
import '../services/text-gestures.service.dart';
import '../services/text-selection.service.dart';
import '../services/transparen-tap-gesture-recognizer.dart';

// Multiple callbacks can be called for one sequence of input gestures.
// An ordinary GestureDetector configured to handle events like tap and double tap will only recognize one or the other.
// This widget detects: the first tap and then, if another tap down occurs within a time limit, the double tap.
class TextGestures extends StatefulWidget {
  final HitTestBehavior? behavior;
  final GlobalKey editorRendererKey;
  final Widget child;

  const TextGestures({
    required this.behavior,
    required this.editorRendererKey,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TextGesturesState();
}

class _TextGesturesState extends State<TextGestures> {
  final _textSelectionService = TextSelectionService();
  final _textGesturesService = TextGesturesService();
  final _highlightsService = HighlightsService();

  Timer? _doubleTapTimer;
  Offset? _lastTapOffset;
  bool _isDoubleTap = false;
  late TargetPlatform _platform;

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    _dragUpdateThrottleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _platform = Theme.of(context).platform;

    return MouseRegion(
      onHover: _handleHover,
      child: RawGestureDetector(
        gestures: _setupGestures(),
        excludeFromSemantics: true,
        behavior: widget.behavior,
        child: widget.child,
      ),
    );
  }

  Map<Type, GestureRecognizerFactory<GestureRecognizer>> _setupGestures() {
    final gestures = <Type, GestureRecognizerFactory>{};

    // A transparent recognizer is used so that TextSelectionGestures and
    // selection handles receive the same tap events.
    gestures[TransparentTapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<TransparentTapGestureRecognizer>(
      () => TransparentTapGestureRecognizer(
        debugOwner: this,
      ),
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
      () => ForcePressGestureRecognizer(
        debugOwner: this,
      ),
      (instance) {
        instance
          ..onStart = _forcePressStarted
          ..onEnd = _forcePressEnded;
      },
    );

    return gestures;
  }

  void _handleHover(PointerHoverEvent event) {
    _highlightsService.onHover(event);
  }

  // The down handler is force-run on success of a single tap and optimistically run before a long press success.
  void _handleTapDown(TapDownDetails details) {
    _textGesturesService.onTapDown(details);

    // This isn't detected as a double tap gesture in the gesture recognizer
    // because it's 2 single taps, each of which may do different things
    // depending on whether it's a single tap, the first tap of a double tap,
    // the second tap held down, a clean double tap etc.
    if (_doubleTapTimer != null &&
        _isWithinDoubleTapTolerance(details.globalPosition)) {
      // If there was already a previous tap, the second down hold/tap is a double tap down.
      _textGesturesService.onDoubleTapDown(details);
      _doubleTapTimer!.cancel();
      _doubleTapTimeout();
      _isDoubleTap = true;
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isDoubleTap) {
      _textGesturesService.onSingleTapUp(details, _platform);
      _highlightsService.onSingleTapUp(details);
      _lastTapOffset = details.globalPosition;
      _doubleTapTimer = Timer(kDoubleTapTimeout, _doubleTapTimeout);
    }

    _isDoubleTap = false;
  }

  void _handleTapCancel() {
    _textGesturesService.onSingleTapCancel();
  }

  DragStartDetails? _lastDragStartDetails;
  DragUpdateDetails? _lastDragUpdateDetails;
  Timer? _dragUpdateThrottleTimer;

  void _handleDragStart(DragStartDetails details) {
    print('\n');
    assert(_lastDragStartDetails == null);
    _lastDragStartDetails = details;
    _textGesturesService.onDragSelectionStart(details);
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

    _textSelectionService.extendSelection(
      _lastDragUpdateDetails!.globalPosition,
      cause: SelectionChangedCause.drag,
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

    _textSelectionService.onSelectionCompleted();

    _dragUpdateThrottleTimer = null;
    _lastDragStartDetails = null;
    _lastDragUpdateDetails = null;
  }

  void _forcePressStarted(ForcePressDetails details) {
    _doubleTapTimer?.cancel();
    _doubleTapTimer = null;

    _textGesturesService.onForcePressStart(details);
  }

  void _forcePressEnded(ForcePressDetails details) {
    _textGesturesService.onForcePressEnd(details);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!_isDoubleTap) {
      _textGesturesService.onSingleLongTapStart(
        details,
        _platform,
        context,
      );
    }
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isDoubleTap) {
      _textGesturesService.onSingleLongTapMoveUpdate(
        details,
        _platform,
      );
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!_isDoubleTap) {
      _textGesturesService.onSingleLongTapEnd(details);
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
