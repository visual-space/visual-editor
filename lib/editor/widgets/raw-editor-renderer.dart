import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../cursor/services/cursor.controller.dart';
import '../../documents/models/document.dart';
import '../../editor/models/text-selection-handlers.type.dart';
import '../../editor/widgets/editor-renderer.dart';

// +++ Do we really need this layer?
class RawEditorRenderer extends MultiChildRenderObjectWidget {
  final ViewportOffset? offset;
  final Document document;
  final TextDirection textDirection;
  final bool scrollable;
  final TextSelection selection;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final TextSelectionChangedHandler onSelectionChanged;
  final TextSelectionCompletedHandler onSelectionCompleted;
  final double scrollBottomInset;
  final EdgeInsetsGeometry padding;
  final double? maxContentWidth;
  final CursorController cursorController;
  final bool floatingCursorDisabled;

  RawEditorRenderer({
    required Key key,
    required List<Widget> children,
    required this.document,
    required this.textDirection,
    required this.scrollable,
    required this.selection,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required this.onSelectionChanged,
    required this.onSelectionCompleted,
    required this.scrollBottomInset,
    required this.cursorController,
    required this.floatingCursorDisabled,
    this.padding = EdgeInsets.zero,
    this.maxContentWidth,
    this.offset,
  }) : super(key: key, children: children);

  @override
  EditorRenderer createRenderObject(BuildContext context) => EditorRenderer(
        offset: offset,
        document: document,
        textDirection: textDirection,
        scrollable: scrollable,
        selection: selection,
        startHandleLayerLink: startHandleLayerLink,
        endHandleLayerLink: endHandleLayerLink,
        onSelectionChanged: onSelectionChanged,
        onSelectionCompleted: onSelectionCompleted,
        cursorController: cursorController,
        padding: padding,
        maxContentWidth: maxContentWidth,
        scrollBottomInset: scrollBottomInset,
        floatingCursorDisabled: floatingCursorDisabled,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant EditorRenderer renderObject,
  ) {
    renderObject
      ..offset = offset
      ..document = document
      ..setContainer(document.root)
      ..textDirection = textDirection
      ..setSelection(selection)
      ..setStartHandleLayerLink(startHandleLayerLink)
      ..setEndHandleLayerLink(endHandleLayerLink)
      ..onSelectionChanged = onSelectionChanged
      ..setScrollBottomInset(scrollBottomInset)
      ..setPadding(padding)
      ..maxContentWidth = maxContentWidth;
  }
}
