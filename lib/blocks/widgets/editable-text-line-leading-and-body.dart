import 'package:flutter/material.dart';

import '../../shared/models/content-proxy-box-renderer.model.dart';
import '../models/text-line-slot.enum.dart';
import 'editable-text-line-box-renderer.dart';
import 'editable-text-line-widget-renderer.dart';

// An element is an instantiation of a widget in the widget tree.
// The editable text line element hosts the leading widget (bullets, checkboxes)
// and the underlying text widget (text spans).
// This widget mounds the 2 parts of editable text line (leading and body) in the slots that are provided.
// It also handles the change detection process for each of the slots as needed (leading or body, or both).
// Slots are used to identify the children cheaply when the framework runs the update cycle.
class EditableTextLineLeadingAndBody extends RenderObjectElement {
  EditableTextLineLeadingAndBody(
    EditableTextLineWidgetRenderer editableTextLineRenderer,
  ) : super(editableTextLineRenderer);

  final Map<TextLineSlot, Element> _slotToChildren = <TextLineSlot, Element>{};

  // Nice wrapper method that retrieves the EditableTextLineWidgetRenderer from the RenderObjectElement (was passed via super() )
  @override
  EditableTextLineWidgetRenderer get widget =>
      super.widget as EditableTextLineWidgetRenderer;

  // aka editableTextLine
  @override
  EditableTextLineBoxRenderer get renderObject =>
      super.renderObject as EditableTextLineBoxRenderer;

  @override
  void visitChildren(ElementVisitor visitor) {
    _slotToChildren.values.forEach(visitor);
  }

  @override
  void forgetChild(Element child) {
    assert(_slotToChildren.containsValue(child));
    assert(child.slot is TextLineSlot);
    assert(_slotToChildren.containsKey(child.slot));
    _slotToChildren.remove(child.slot);
    super.forgetChild(child);
  }

  // We mount the leading widget and the body widget (editable text line) as two children of this particular component.
  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _mountChild(widget.leading, TextLineSlot.LEADING);
    _mountChild(widget.underlyingText, TextLineSlot.UNDERLYING_TEXT);
  }

  @override
  void update(EditableTextLineWidgetRenderer newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _updateChild(widget.leading, TextLineSlot.LEADING);
    _updateChild(widget.underlyingText, TextLineSlot.UNDERLYING_TEXT);
  }

  @override
  void insertRenderObjectChild(RenderBox child, TextLineSlot? slot) {
    // assert(child is RenderBox);
    _updateRenderObject(child, slot);
    assert(renderObject.children.keys.contains(slot));
  }

  @override
  void removeRenderObjectChild(RenderObject child, TextLineSlot? slot) {
    assert(child is RenderBox);
    assert(renderObject.children[slot!] == child);
    _updateRenderObject(null, slot);
    assert(!renderObject.children.keys.contains(slot));
  }

  @override
  void moveRenderObjectChild(
    RenderObject child,
    dynamic oldSlot,
    dynamic newSlot,
  ) {
    throw UnimplementedError();
  }

  void _mountChild(Widget? widget, TextLineSlot slot) {
    final oldChild = _slotToChildren[slot];
    final newChild = updateChild(oldChild, widget, slot);

    if (oldChild != null) {
      _slotToChildren.remove(slot);
    }

    if (newChild != null) {
      _slotToChildren[slot] = newChild;
    }
  }

  void _updateRenderObject(RenderBox? child, TextLineSlot? slot) {
    switch (slot) {
      case TextLineSlot.LEADING:
        renderObject.setLeading(child);
        break;
      case TextLineSlot.UNDERLYING_TEXT:
        renderObject.setBody(child as RenderContentProxyBox?);
        break;
      default:
        throw UnimplementedError();
    }
  }

  void _updateChild(Widget? widget, TextLineSlot slot) {
    final oldChild = _slotToChildren[slot];
    final newChild = updateChild(oldChild, widget, slot);

    if (oldChild != null) {
      _slotToChildren.remove(slot);
    }

    if (newChild != null) {
      _slotToChildren[slot] = newChild;
    }
  }
}
