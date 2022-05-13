import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../editor/widgets/editor-renderer.dart';
import '../models/text-selection-handle-position.enum.dart';

// This widget represents a single draggable text selection handle.
class TextSelectionHandleOverlay extends StatefulWidget {
  const TextSelectionHandleOverlay({
    required this.selection,
    required this.position,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required this.renderObject,
    required this.onSelectionHandleChanged,
    required this.onSelectionHandleTapped,
    required this.selectionControls,
    this.dragStartBehavior = DragStartBehavior.start,
    Key? key,
  }) : super(key: key);

  final TextSelection selection;
  final TextSelectionHandlePosition position;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final RenderEditor renderObject;
  final ValueChanged<TextSelection?> onSelectionHandleChanged;
  final VoidCallback? onSelectionHandleTapped;
  final TextSelectionControls selectionControls;
  final DragStartBehavior dragStartBehavior;

  @override
  TextSelectionHandleOverlayState createState() =>
      TextSelectionHandleOverlayState();

  ValueListenable<bool> get _visibility {
    switch (position) {
      case TextSelectionHandlePosition.START:
        return renderObject.selectionStartInViewport;
      case TextSelectionHandlePosition.END:
        return renderObject.selectionEndInViewport;
      default:
        throw 'Invalid position';
    }
  }
}

class TextSelectionHandleOverlayState extends State<TextSelectionHandleOverlay>
    with SingleTickerProviderStateMixin {
  // ignore: unused_field
  late Offset _dragPosition;

  late AnimationController _controller;

  Animation<double> get _opacity => _controller.view;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _handleVisibilityChanged();
    widget._visibility.addListener(_handleVisibilityChanged);
  }

  void _handleVisibilityChanged() {
    if (widget._visibility.value) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void didUpdateWidget(TextSelectionHandleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget._visibility.removeListener(_handleVisibilityChanged);
    _handleVisibilityChanged();
    widget._visibility.addListener(_handleVisibilityChanged);
  }

  @override
  void dispose() {
    widget._visibility.removeListener(_handleVisibilityChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    final textPosition = widget.position == TextSelectionHandlePosition.START
        ? widget.selection.base
        : widget.selection.extent;
    final lineHeight = widget.renderObject.preferredLineHeight(textPosition);
    final handleSize = widget.selectionControls.getHandleSize(lineHeight);
    _dragPosition = details.globalPosition + Offset(0, -handleSize.height);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragPosition += details.delta;
    final position =
        widget.renderObject.getPositionForOffset(details.globalPosition);
    if (widget.selection.isCollapsed) {
      widget.onSelectionHandleChanged(
        TextSelection.fromPosition(position),
      );
      return;
    }

    final isNormalized =
        widget.selection.extentOffset >= widget.selection.baseOffset;
    TextSelection newSelection;
    switch (widget.position) {
      case TextSelectionHandlePosition.START:
        newSelection = TextSelection(
          baseOffset:
              isNormalized ? position.offset : widget.selection.baseOffset,
          extentOffset:
              isNormalized ? widget.selection.extentOffset : position.offset,
        );
        break;
      case TextSelectionHandlePosition.END:
        newSelection = TextSelection(
          baseOffset:
              isNormalized ? widget.selection.baseOffset : position.offset,
          extentOffset:
              isNormalized ? position.offset : widget.selection.extentOffset,
        );
        break;
      default:
        throw 'Invalid widget.position';
    }

    if (newSelection.baseOffset >= newSelection.extentOffset) {
      return; // don't allow order swapping.
    }

    widget.onSelectionHandleChanged(newSelection);
  }

  void _handleTap() {
    if (widget.onSelectionHandleTapped != null) {
      widget.onSelectionHandleTapped!();
    }
  }

  @override
  Widget build(BuildContext context) {
    late LayerLink layerLink;
    TextSelectionHandleType? type;

    switch (widget.position) {
      case TextSelectionHandlePosition.START:
        layerLink = widget.startHandleLayerLink;
        type = _chooseType(
          widget.renderObject.textDirection,
          TextSelectionHandleType.left,
          TextSelectionHandleType.right,
        );
        break;
      case TextSelectionHandlePosition.END:
        // For collapsed selections, we shouldn't be building the [end] handle.
        assert(!widget.selection.isCollapsed);
        layerLink = widget.endHandleLayerLink;
        type = _chooseType(
          widget.renderObject.textDirection,
          TextSelectionHandleType.right,
          TextSelectionHandleType.left,
        );
        break;
    }

    // TODO: This logic doesn't work for TextStyle.height larger 1.
    // It makes the extent handle top end on iOS extend too high which makes
    // stick out above the selection background.
    // May have to use getSelectionBoxes instead of preferredLineHeight.
    // or expose TextStyle on the render object and calculate
    // preferredLineHeight / style.height
    final textPosition = widget.position == TextSelectionHandlePosition.START
        ? widget.selection.base
        : widget.selection.extent;
    final lineHeight = widget.renderObject.preferredLineHeight(textPosition);
    final handleAnchor =
        widget.selectionControls.getHandleAnchor(type!, lineHeight);
    final handleSize = widget.selectionControls.getHandleSize(lineHeight);

    final handleRect = Rect.fromLTWH(
      -handleAnchor.dx,
      -handleAnchor.dy,
      handleSize.width,
      handleSize.height,
    );

    // Make sure the GestureDetector is big enough to be easily interactive.
    final interactiveRect = handleRect.expandToInclude(
      Rect.fromCircle(
          center: handleRect.center, radius: kMinInteractiveDimension / 2),
    );
    final padding = RelativeRect.fromLTRB(
      math.max((interactiveRect.width - handleRect.width) / 2, 0),
      math.max((interactiveRect.height - handleRect.height) / 2, 0),
      math.max((interactiveRect.width - handleRect.width) / 2, 0),
      math.max((interactiveRect.height - handleRect.height) / 2, 0),
    );

    return CompositedTransformFollower(
      link: layerLink,
      offset: interactiveRect.topLeft,
      showWhenUnlinked: false,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          alignment: Alignment.topLeft,
          width: interactiveRect.width,
          height: interactiveRect.height,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            dragStartBehavior: widget.dragStartBehavior,
            onPanStart: _handleDragStart,
            onPanUpdate: _handleDragUpdate,
            onTap: _handleTap,
            child: Padding(
              padding: EdgeInsets.only(
                left: padding.left,
                top: padding.top,
                right: padding.right,
                bottom: padding.bottom,
              ),
              child: widget.selectionControls.buildHandle(
                context,
                type,
                lineHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextSelectionHandleType? _chooseType(
    TextDirection textDirection,
    TextSelectionHandleType ltrType,
    TextSelectionHandleType rtlType,
  ) {
    if (widget.selection.isCollapsed) return TextSelectionHandleType.collapsed;

    switch (textDirection) {
      case TextDirection.ltr:
        return ltrType;
      case TextDirection.rtl:
        return rtlType;
    }
  }
}
