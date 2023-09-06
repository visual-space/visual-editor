import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../doc-tree/services/coordinates.service.dart';
import '../../editor/widgets/editor-textarea-renderer.dart';
import '../../shared/state/editor.state.dart';
import '../models/drag-text-selection.model.dart';
import '../models/text-selection-handle-position.enum.dart';
import '../services/selection-handles.service.dart';
import '../widgets/text-selection-handles-overlay.dart';

// Manages a pair of text selection handles (overlay entries for selection handles).
// The selection handles are displayed in the Overlay that most closely encloses the given BuildContext.
class SelectionHandlesController {
  late final CoordinatesService _coordinatesService;
  late final SelectionHandlesService _selectionHandlesService;

  TextEditingValue plainText;

  // Whether selection handles are visible.
  // Set to false if you want to hide the handles. Use this property to show or hide the handle without rebuilding them.
  // If this method is called while the SchedulerBinding.schedulerPhase is SchedulerPhase.persistentCallbacks,
  // i.e. during the build, layout, or paint phases (see WidgetsBinding.drawFrame),
  // then the update is delayed until the post-frame callbacks phase.
  // Otherwise the update is done synchronously.
  // This means that it is safe to call during builds, but also that if you do call this during a build,
  // the UI will not update until the next frame (i.e. many milliseconds later).
  // Defaults to false.
  bool handlesVisible = false;

  // The context in which the selection handles should appear.
  // This context must have an Overlay as an ancestor because this object
  // will display the text selection handles in that Overlay.
  // The context must not be null and must have an Overlay as an ancestor.
  late BuildContext _context;

  // Debugging information for explaining why the Overlay is required.
  final Widget debugRequiredFor;

  // The editable line in which the selected text is being displayed.
  final EditorTextAreaRenderer renderObject;

  // Builds text selection handles and buttons.
  late TextSelectionControls _textSelectionControls;

  // The delegate for manipulating the current selection in the owning text field.
  final TextSelectionDelegate selectionDelegate;

  // Determines the way that drag start behavior is handled.
  // If set to DragStartBehavior.start, handle drag behavior will begin upon the detection of a drag gesture.
  // If set to DragStartBehavior.down it will begin when a down event is first detected.
  // In general, setting this to DragStartBehavior.start will make drag animation smoother and
  // setting it to DragStartBehavior.down will make drag behavior feel slightly more reactive.
  // By default, the drag start behavior is DragStartBehavior.start.
  // See also: * DragGestureRecognizer.dragStartBehavior, which gives an example for the different behaviors.
  final DragStartBehavior dragStartBehavior;

  // A callback that's invoked when a selection handle is tapped.
  // Both regular taps and long presses invoke this callback, but a drag gesture won't.
  final VoidCallback? onSelectionHandleTapped;

  // Maintains the status of the clipboard for determining if its contents can be pasted or not.
  // Useful because the actual value of the clipboard can only be checked asynchronously (see Clipboard.getData).
  final ClipboardStatusNotifier clipboardStatus;
  late AnimationController _toolbarController;

  // A pair of handles. If this is non-null, there are always 2, though the
  // second is hidden when the selection is collapsed.
  List<OverlayEntry>? _handles;

  // A copy/paste buttons.
  OverlayEntry? toolbar;

  TextSelection get _selection => plainText.selection;

  Animation<double> get _toolbarOpacity => _toolbarController.view;
  late EditorState _state;

  void cacheStateStore(EditorState state) {
    _state = state;
  }

  SelectionHandlesController({
    required this.plainText,
    required this.renderObject,
    required this.debugRequiredFor,
    required textSelectionControls,
    required this.selectionDelegate,
    required this.clipboardStatus,
    required EditorState state,
    this.onSelectionHandleTapped,
    this.dragStartBehavior = DragStartBehavior.start,
    this.handlesVisible = false,
  }) {
    _coordinatesService = CoordinatesService(state);
    _selectionHandlesService = SelectionHandlesService(state);

    cacheStateStore(state);

    // The context must not be null and must have an Overlay as an ancestor.
    _context = state.refs.widget.context;
    final overlay = Overlay.of(_context, rootOverlay: true);

    _textSelectionControls = textSelectionControls ??
        _state.platformStyles.styles.textSelectionControls;

    _toolbarController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: overlay,
    );
  }

  // TODO Review why this method is not called
  void setHandlesVisible(bool visible) {
    if (handlesVisible == visible) {
      return;
    }
    handlesVisible = visible;
    // If we are in build state, it will be too late to update visibility.
    // We will need to schedule the build in next frame.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback(markNeedsBuild);
    } else {
      markNeedsBuild();
    }
  }

  // TODO Review why this method is not called
  // Destroys the handles by removing them from overlay.
  void hideHandles() {
    if (_handles == null) {
      return;
    }
    _handles![0].remove();
    _handles![1].remove();
    _handles = null;
  }

  // Hides the buttons part of the overlay.
  // To hide the whole overlay, see [hide].
  void hideToolbar() {
    assert(toolbar != null);
    _toolbarController.stop();
    toolbar!.remove();
    toolbar = null;
  }

  // Shows the buttons by inserting it into the [context]'s overlay.
  void showToolbar() {
    assert(toolbar == null);

    toolbar = OverlayEntry(builder: _toolbar);
    Overlay.of(
      _context,
      rootOverlay: true,
      debugRequiredFor: debugRequiredFor,
    ).insert(toolbar!);
    _toolbarController.forward(from: 0);

    // Make sure handles are visible as well
    if (_handles == null) {
      showHandles();
    }
  }

  // Updates the overlay after the selection has changed.
  // If this method is called while the [SchedulerBinding.schedulerPhase] is [SchedulerPhase.persistentCallbacks],
  // i.e. during the build, layout, or paint phases (see [WidgetsBinding.drawFrame]),
  // then the update is delayed until the post-frame callbacks phase.
  // Otherwise the update is done synchronously.
  // This means that it is safe to call during builds, but also that if you do call this during a build,
  // the UI will not update until the next frame (i.e. many milliseconds later).
  void update(TextEditingValue newValue) {
    if (plainText == newValue) {
      return;
    }

    plainText = newValue;

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback(markNeedsBuild);
    } else {
      markNeedsBuild();
    }
  }

  // Hides the entire overlay including the buttons and the handles.
  void hide() {
    if (_handles != null) {
      _handles![0].remove();
      _handles![1].remove();
      _handles = null;
    }

    if (toolbar != null) {
      hideToolbar();
    }
  }

  // Final cleanup.
  void dispose() {
    hide();
    _toolbarController.dispose();
  }

  // Builds the handles by inserting them into the [context]'s overlay.
  void showHandles() {
    assert(_handles == null);

    _handles = <OverlayEntry>[
      OverlayEntry(
        builder: (context) => _handle(
          context,
          TextSelectionHandlePosition.START,
        ),
      ),
      OverlayEntry(
        builder: (context) => _handle(
          context,
          TextSelectionHandlePosition.END,
        ),
      ),
    ];

    Overlay.of(
      _context,
      rootOverlay: true,
      debugRequiredFor: debugRequiredFor,
    ).insertAll(_handles!);
  }

  // Causes the overlay to update its rendering.
  // This is intended to be called when the [renderObject] may have changed its
  // text metrics (e.g. because the text was scrolled).
  void updateSelectionHandlesLocation() {
    markNeedsBuild();
  }

  // === WIDGET ===

  Widget _toolbar(BuildContext context) {
    // Find the horizontal midpoint, just above the selected text.
    List<TextSelectionPoint> endpoints;

    try {
      // Building with an invalid selection will throw an exception.
      // This happens where the selection has changed, but the buttons hasn't been dismissed yet.
      endpoints = _selectionHandlesService.getEndpointsForSelection(_selection);
    } catch (_) {
      return Container();
    }

    // Computes the position of the editor relative to viewport
    final editingRegion = Rect.fromPoints(
      renderObject.localToGlobal(Offset.zero),
      renderObject.localToGlobal(
        renderObject.size.bottomRight(Offset.zero),
      ),
    );

    final baseLineHeight = _coordinatesService.preferredLineHeight(
      _selection.base,
    );
    final extentLineHeight = _coordinatesService.preferredLineHeight(
      _selection.extent,
    );
    final smallestLineHeight = math.min(baseLineHeight, extentLineHeight);
    final isMultiline = endpoints.last.point.dy - endpoints.first.point.dy >
        smallestLineHeight / 2;

    // If the selected text spans more than 1 line, horizontally center the buttons.
    // Derived from both iOS and Android.
    final midX = isMultiline
        ? editingRegion.width / 2
        : (endpoints.first.point.dx + endpoints.last.point.dx) / 2;

    final midpoint = Offset(
      midX,
      // The y-coordinate won't be made use of most likely.
      endpoints[0].point.dy - baseLineHeight,
    );

    return FadeTransition(
      opacity: _toolbarOpacity,
      child: CompositedTransformFollower(
        link: _state.selectionLayers.toolbarLayerLink,
        showWhenUnlinked: false,
        offset: -editingRegion.topLeft,
        child:  _textSelectionControls.buildToolbar(
          context,
          editingRegion,
          baseLineHeight,
          midpoint,
          endpoints,
          selectionDelegate,
          clipboardStatus,
          null,
        ),
      ),
    );
  }

  Widget _handle(BuildContext context, TextSelectionHandlePosition position) {
    if (_selection.isCollapsed && position == TextSelectionHandlePosition.END) {
      return Container();
    }

    return Visibility(
      visible: handlesVisible,
      child: TextSelectionHandleOverlay(
        onSelectionHandleChanged: (newSelection) {
          _handleSelectionHandleChanged(newSelection, position);
        },
        onSelectionHandleTapped: onSelectionHandleTapped,
        renderObject: renderObject,
        selection: _selection,
        textSelectionControls: _textSelectionControls,
        position: position,
        dragStartBehavior: dragStartBehavior,
        state: _state,
      ),
    );
  }

  void _handleSelectionHandleChanged(
    TextSelection? newSelection,
    TextSelectionHandlePosition position,
  ) {
    TextPosition textPosition;

    switch (position) {
      case TextSelectionHandlePosition.START:
        textPosition = newSelection != null
            ? newSelection.base
            : const TextPosition(offset: 0);
        break;

      case TextSelectionHandlePosition.END:
        textPosition = newSelection != null
            ? newSelection.extent
            : const TextPosition(offset: 0);
        break;

      default:
        throw 'Invalid position';
    }

    final currSelection = newSelection != null
        ? DragTextSelection(
            baseOffset: newSelection.baseOffset,
            extentOffset: newSelection.extentOffset,
            affinity: newSelection.affinity,
            isDirectional: newSelection.isDirectional,
            first: position == TextSelectionHandlePosition.START,
          )
        : null;

    selectionDelegate
      ..userUpdateTextEditingValue(
          plainText.copyWith(
            selection: currSelection,
            composing: TextRange.empty,
          ),
          SelectionChangedCause.drag)
      ..bringIntoView(textPosition);
  }

  void markNeedsBuild([Duration? duration]) {
    if (_handles != null) {
      _handles![0].markNeedsBuild();
      _handles![1].markNeedsBuild();
    }

    toolbar?.markNeedsBuild();
  }
}
