import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../documents/models/nodes/container.model.dart';
import '../models/editable-box-renderer.model.dart';

class EditableContainerParentData
    extends ContainerBoxParentData<EditableBoxRenderer> {}

// Used by widgets that render multiline text in Visual Editor (the big editor and blocks of text).
// Provides methods for computing the widget layout based on constraints from the parent.
// Used/Extended by both the EditorRendererInner and the EditableTextBlockRenderer.
// Same layout computing logic needed by both text renderers.
class MultilineTextAreaRenderer extends RenderBox
    with
        ContainerRenderObjectMixin<EditableBoxRenderer,
            EditableContainerParentData>,
        RenderBoxContainerDefaultsMixin<EditableBoxRenderer,
            EditableContainerParentData> {
  MultilineTextAreaRenderer({
    required ContainerM container,
    required this.textDirection,
    this.padding = EdgeInsets.zero,
    List<EditableBoxRenderer>? children,
  })  : assert(padding.isNonNegative),
        containerRef = container {
    addAll(children);
  }

  ContainerM containerRef;
  TextDirection textDirection;
  EdgeInsetsGeometry padding;
  EdgeInsets? _resolvedPadding;

  ContainerM get container => containerRef;

  void setContainer(ContainerM _container) {
    if (containerRef == _container) {
      return;
    }

    containerRef = _container;
    markNeedsLayout();
  }

  EdgeInsets? get resolvedPadding => _resolvedPadding;

  void resolvePadding() {
    if (_resolvedPadding != null) {
      return;
    }

    _resolvedPadding = padding.resolve(textDirection);
    _resolvedPadding = _resolvedPadding!.copyWith(left: _resolvedPadding!.left);

    assert(_resolvedPadding!.isNonNegative);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is EditableContainerParentData) {
      return;
    }

    child.parentData = EditableContainerParentData();
  }

  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth);

    resolvePadding();

    assert(_resolvedPadding != null);

    var mainAxisExtent = _resolvedPadding!.top;
    var child = firstChild;
    final innerConstraints = BoxConstraints.tightFor(
      width: constraints.maxWidth,
    ).deflate(_resolvedPadding!);

    while (child != null) {
      child.layout(innerConstraints, parentUsesSize: true);
      final childParentData = (child.parentData as EditableContainerParentData)
        ..offset = Offset(_resolvedPadding!.left, mainAxisExtent);
      mainAxisExtent += child.size.height;
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }

    mainAxisExtent += _resolvedPadding!.bottom;
    size = constraints.constrain(Size(constraints.maxWidth, mainAxisExtent));

    assert(size.isFinite);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    resolvePadding();

    return _getIntrinsicCrossAxis((child) {
      final childHeight = math.max<double>(
        0,
        height - _resolvedPadding!.top + _resolvedPadding!.bottom,
      );

      return child.getMinIntrinsicWidth(childHeight) +
          _resolvedPadding!.left +
          _resolvedPadding!.right;
    });
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    resolvePadding();

    return _getIntrinsicCrossAxis((child) {
      final childHeight = math.max<double>(
        0,
        height - _resolvedPadding!.top + _resolvedPadding!.bottom,
      );

      return child.getMaxIntrinsicWidth(childHeight) +
          _resolvedPadding!.left +
          _resolvedPadding!.right;
    });
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    resolvePadding();

    return _getIntrinsicMainAxis((child) {
      final childWidth = math.max<double>(
        0,
        width - _resolvedPadding!.left + _resolvedPadding!.right,
      );

      return child.getMinIntrinsicHeight(childWidth) +
          _resolvedPadding!.top +
          _resolvedPadding!.bottom;
    });
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    resolvePadding();

    return _getIntrinsicMainAxis((child) {
      final childWidth = math.max<double>(
        0,
        width - _resolvedPadding!.left + _resolvedPadding!.right,
      );

      return child.getMaxIntrinsicHeight(childWidth) +
          _resolvedPadding!.top +
          _resolvedPadding!.bottom;
    });
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    resolvePadding();

    return defaultComputeDistanceToFirstActualBaseline(baseline)! +
        _resolvedPadding!.top;
  }

  // === PRIVATE ===

  double _getIntrinsicCrossAxis(double Function(RenderBox child) childSize) {
    var extent = 0.0;
    var child = firstChild;

    while (child != null) {
      extent = math.max(extent, childSize(child));
      final childParentData = child.parentData as EditableContainerParentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  double _getIntrinsicMainAxis(double Function(RenderBox child) childSize) {
    var extent = 0.0;
    var child = firstChild;

    while (child != null) {
      extent += childSize(child);
      final childParentData = child.parentData as EditableContainerParentData;
      child = childParentData.nextSibling;
    }

    return extent;
  }
}
