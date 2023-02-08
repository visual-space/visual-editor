import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../doc-tree/services/coordinates.service.dart';
import '../../highlights/services/highlights-hover.service.dart';
import '../../markers/services/markers-hover.service.dart';
import '../../selection/services/selection.service.dart';
import '../../selection/services/transparent-tap-gesture-recognizer.dart';
import '../../shared/state/editor.state.dart';
import '../services/text-gestures.service.dart';

// Multiple callbacks can be called for one sequence of input gestures.
// An ordinary GestureDetector configured to handle events like tap and double tap will only recognize one or the other.
// This widget detects: the first tap and then, if another tap down occurs within a time limit, the double tap.
// Most gestures end up calling runBuild() to refresh the document widget tree.
// ignore: must_be_immutable
class TextGestures extends StatefulWidget {
  final HitTestBehavior? behavior;
  final Widget child;
  late EditorState _state;

  TextGestures({
    required this.behavior,
    required this.child,
    required EditorState state,
    Key? key,
  }) : super(key: key) {
    _cacheStateStore(state);
  }

  @override
  State<StatefulWidget> createState() => _TextGesturesState();

  void _cacheStateStore(EditorState state) {
    _state = state;
  }
}

class _TextGesturesState extends State<TextGestures> {
  late final SelectionService _selectionService;
  late final TextGesturesService _textGesturesService;
  late final HighlightsHoverService _highlightsHoverService;
  late final MarkersHoverService _markersHoverService;
  late final CoordinatesService _coordinatesService;

  Timer? _doubleTapTimer;
  Offset? _lastTapOffset;
  bool _isDoubleTap = false;
  late TargetPlatform _platform;

  @override
  void initState() {
    _selectionService = SelectionService(widget._state);
    _textGesturesService = TextGesturesService(widget._state);
    _highlightsHoverService = HighlightsHoverService(widget._state);
    _markersHoverService = MarkersHoverService(widget._state);
    _coordinatesService = CoordinatesService(widget._state);
    super.initState();
  }

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
        gestures: _getGestures(),
        excludeFromSemantics: true,
        behavior: widget.behavior,
        child: widget.child,
      ),
    );
  }

  // === UTILS ===

  // Most gestures end up calling runBuild() to refresh the document widget tree.
  Map<Type, GestureRecognizerFactory<GestureRecognizer>> _getGestures() {
    return {
      // A transparent recognizer is used so that TextSelectionGestures and
      // selection handles receive the same tap events.
      TransparentTapGestureRecognizer:
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
      ),

      LongPressGestureRecognizer:
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
      ),

      HorizontalDragGestureRecognizer:
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
      ),

      ForcePressGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<ForcePressGestureRecognizer>(
        () => ForcePressGestureRecognizer(
          debugOwner: this,
        ),
        (instance) {
          instance
            ..onStart = _forcePressStarted
            ..onEnd = _forcePressEnded;
        },
      ),
    };
  }

  void _handleHover(PointerHoverEvent event) {
    _highlightsHoverService.onHover(event);
    _markersHoverService.onHover(event);
  }

  // The down handler is force-run on success of a single tap and optimistically run before a long press success.
  void _handleTapDown(TapDownDetails details) {
    final hasDoubleTapTolerance = _hasDoubleTapTolerance(
      details.globalPosition,
    );
    _textGesturesService.onTapDown(details);

    // This isn't detected as a double tap gesture in the gesture recognizer
    // because it's 2 single taps, each of which may do different things
    // depending on whether it's a single tap, the first tap of a double tap,
    // the second tap held down, a clean double tap etc.
    if (_doubleTapTimer != null && hasDoubleTapTolerance) {
      // If there was already a previous tap, the second down hold/tap is a double tap down.
      _textGesturesService.onDoubleTapDown(details);
      _doubleTapTimer!.cancel();
      _doubleTapTimeout();
      _isDoubleTap = true;
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isDoubleTap) {
      // Controller callback
      if (widget._state.config.onTapUp != null &&
          widget._state.config.onTapUp!(
            details,
            _coordinatesService.getPositionForOffset,
          )) {
        return;
      }

      _textGesturesService.onSingleTapUp(details, _platform);
      _highlightsHoverService.onSingleTapUp(details);
      _markersHoverService.onSingleTapUp(details);
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
  // Once a selection is started then this callback is the one that keeps updating the text.
  void _handleDragUpdateThrottled() {
    assert(_lastDragStartDetails != null);
    assert(_lastDragUpdateDetails != null);

    _selectionService.extendSelection(
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

    _selectionService.callOnSelectionCompleted();

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
      _textGesturesService.onSingleLongTapStart(details, _platform, context);
    }
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isDoubleTap) {
      _textGesturesService.onSingleLongTapMoveUpdate(details, _platform);
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

  bool _hasDoubleTapTolerance(Offset secondTapOffset) {
    if (_lastTapOffset == null) {
      return false;
    }

    return (secondTapOffset - _lastTapOffset!).distance <= kDoubleTapSlop;
  }
}
