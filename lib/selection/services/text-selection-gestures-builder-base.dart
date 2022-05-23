import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../editor/models/editor-state.model.dart';
import '../../editor/widgets/editor-renderer.dart';
import '../models/gesture-detector-builder-delegate.dart';
import '../widgets/text-selection-gestures.dart';

// Builds a TextSelectionGestures to wrap an VisualEditor.
// Implements sensible defaults for many user interactions with an VisualEditor.
// See the documentation of the various gesture handler methods, e.g. onTapDown, onForcePressStart, etc.
// Subclasses of TextSelectionGesturesBuilder can change the behavior performed in response to these
// gesture events by overriding the corresponding handler methods of this class.
// The resulting TextSelectionGestures to wrap an VisualEditor is obtained by calling buildGestureDetector.
// See also:
//  * TextField, which uses a subclass to implement the Material-specific gesture logic of an VisualEditor.
//  * CupertinoTextField, which uses a subclass to implement the Cupertino-specific gesture logic of an VisualEditor.
class TextSelectionGesturesBuilderBase {
  // The delegate for this TextSelectionGesturesBuilder.
  // The delegate provides the builder with information about what actions can currently be performed on the textfield.
  // Based on this, the builder adds the correct gesture handlers to the gesture detector.
  @protected
  final TextSelectionGesturesBuilderDelegate delegate;

  TextSelectionGesturesBuilderBase({
    required this.delegate,
  });

  // Whether to show the selection buttons.
  // It is based on the signal source when a onTapDown is called.
  // Will return true if current onTapDown event is triggered by a touch or a stylus.
  bool shouldShowSelectionToolbar = true;

  // Returns a TextSelectionGestures configured with the handlers provided by this builder.
  // The child or its subtree should contain VisualEditor.
  Widget build({
    required HitTestBehavior behavior,
    required Widget child,
    Key? key,
  }) {
    return TextSelectionGestures(
      key: key,
      onHover: onHover,
      onTapDown: onTapDown,
      onForcePressStart: delegate.forcePressEnabled ? onForcePressStart : null,
      onForcePressEnd: delegate.forcePressEnabled ? onForcePressEnd : null,
      onSingleTapUp: onSingleTapUp,
      onSingleTapCancel: onSingleTapCancel,
      onSingleLongTapStart: onSingleLongTapStart,
      onSingleLongTapMoveUpdate: onSingleLongTapMoveUpdate,
      onSingleLongTapEnd: onSingleLongTapEnd,
      onDoubleTapDown: onDoubleTapDown,
      onDragSelectionStart: onDragSelectionStart,
      onDragSelectionUpdate: onDragSelectionUpdate,
      onDragSelectionEnd: onDragSelectionEnd,
      behavior: behavior,
      child: child,
    );
  }

  // The State of the VisualEditor for which the builder will provide a TextSelectionGestures.
  @protected
  EditorState? get editor => delegate.editableTextKey.currentState;

  // The RenderObject of the VisualEditor for which the builder will provide a TextSelectionGestures.
  @protected
  RenderEditor? get renderEditor => editor?.renderEditor;

  @protected
  void onHover(PointerHoverEvent event) {}

  // Handler for TextSelectionGestures.onTapDown.
  // By default, it forwards the tap to RenderEditable.handleTapDown and sets shouldShowSelectionToolbar
  // to true if the tap was initiated by a finger or stylus.
  // See also: TextSelectionGestures.onTapDown, which triggers this callback.
  @protected
  void onTapDown(TapDownDetails details) {
    renderEditor!.handleTapDown(details);
    // The selection overlay should only be shown when the user is interacting
    // through a touch screen (via either a finger or a stylus).
    // A mouse shouldn't trigger the selection overlay.
    // For backwards-compatibility, we treat a null kind the same as touch.
    final kind = details.kind;
    shouldShowSelectionToolbar = kind == null ||
        kind == PointerDeviceKind.touch ||
        kind == PointerDeviceKind.stylus;
  }

  // Handler for TextSelectionGestures.onForcePressStart.
  // By default, it selects the word at the position of the force press, if selection is enabled.
  // This callback is only applicable when force press is enabled.
  // See also: TextSelectionGestures.onForcePressStart, which triggers this callback.
  @protected
  void onForcePressStart(ForcePressDetails details) {
    assert(delegate.forcePressEnabled);
    shouldShowSelectionToolbar = true;
    if (delegate.selectionEnabled) {
      renderEditor!.selectWordsInRange(
        details.globalPosition,
        null,
        SelectionChangedCause.forcePress,
      );
    }
  }

  // Handler for TextSelectionGestures.onForcePressEnd.
  // By default, it selects words in the range specified in details and shows buttons if it is necessary.
  // This callback is only applicable when force press is enabled.
  // See also: TextSelectionGestures.onForcePressEnd, which triggers this callback.
  @protected
  void onForcePressEnd(ForcePressDetails details) {
    assert(delegate.forcePressEnabled);
    renderEditor!.selectWordsInRange(
      details.globalPosition,
      null,
      SelectionChangedCause.forcePress,
    );
    if (shouldShowSelectionToolbar) {
      editor!.showToolbar();
    }
  }

  // Handler for TextSelectionGestures.onSingleTapUp.
  // By default, it selects word edge if selection is enabled.
  // See also: TextSelectionGestures.onSingleTapUp, which triggers this callback.
  @protected
  void onSingleTapUp(TapUpDetails details) {
    if (delegate.selectionEnabled) {
      renderEditor!.selectWordEdge(SelectionChangedCause.tap);
    }
  }

  // Handler for TextSelectionGestures.onSingleTapCancel.
  // By default, it services as place holder to enable subclass override.
  // See also: TextSelectionGestures.onSingleTapCancel, which triggers this callback.
  @protected
  void onSingleTapCancel() {
    // Subclass should override this method if needed.
  }

  // Handler for TextSelectionGestures.onSingleLongTapStart.
  // By default, it selects text position specified in details if selection is enabled.
  // See also: TextSelectionGestures.onSingleLongTapStart, which triggers this callback.
  @protected
  void onSingleLongTapStart(LongPressStartDetails details) {
    if (delegate.selectionEnabled) {
      renderEditor!.selectPositionAt(
        from: details.globalPosition,
        cause: SelectionChangedCause.longPress,
      );
    }
  }

  // Handler for TextSelectionGestures.onSingleLongTapMoveUpdate
  // By default, it updates the selection location specified in details if selection is enabled.
  // See also: TextSelectionGestures.onSingleLongTapMoveUpdate, which triggers this callback.
  @protected
  void onSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    if (delegate.selectionEnabled) {
      renderEditor!.selectPositionAt(
        from: details.globalPosition,
        cause: SelectionChangedCause.longPress,
      );
    }
  }

  // Handler for TextSelectionGestures.onSingleLongTapEnd.
  // By default, it shows buttons if necessary.
  // See also: TextSelectionGestures.onSingleLongTapEnd, which triggers this callback.
  @protected
  void onSingleLongTapEnd(LongPressEndDetails details) {
    if (shouldShowSelectionToolbar) {
      editor!.showToolbar();
    }
  }

  // Handler for TextSelectionGestures.onDoubleTapDown.
  // By default, it selects a word through RenderEditable.selectWord if  selectionEnabled and shows buttons if necessary.
  // See also: TextSelectionGestures.onDoubleTapDown, which triggers this callback.
  @protected
  void onDoubleTapDown(TapDownDetails details) {
    if (delegate.selectionEnabled) {
      renderEditor!.selectWord(SelectionChangedCause.tap);

      // Allow the selection to get updated before trying to bring up toolbars.
      // If double tap happens on an editor that doesn't have focus,
      // selection hasn't been set when the toolbars get added.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (shouldShowSelectionToolbar) {
          editor!.showToolbar();
        }
      });
    }
  }

  // Handler for TextSelectionGestures.onDragSelectionStart.
  // By default, it selects a text position specified in details.
  // See also:  TextSelectionGestures.onDragSelectionStart, which triggers this callback.
  @protected
  void onDragSelectionStart(DragStartDetails details) {
    renderEditor!.handleDragStart(details);
  }

  // Handler for TextSelectionGestures.onDragSelectionUpdate.
  // By default, it updates the selection location specified in the provided details objects.
  // See also: TextSelectionGestures.onDragSelectionUpdate, which triggers this callback.
  // /lib/src/material/text_field.dart
  @protected
  void onDragSelectionUpdate(
      DragStartDetails startDetails, DragUpdateDetails updateDetails) {
    renderEditor!.extendSelection(updateDetails.globalPosition,
        cause: SelectionChangedCause.drag);
  }

  // Handler for TextSelectionGestures.onDragSelectionEnd.
  // By default, it services as place holder to enable subclass override.
  // See also: TextSelectionGestures.onDragSelectionEnd, which triggers this callback.
  @protected
  void onDragSelectionEnd(DragEndDetails details) {
    renderEditor!.handleDragEnd(details);
  }
}
