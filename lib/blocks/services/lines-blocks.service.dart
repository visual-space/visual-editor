import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../documents/models/attributes/attributes-aliases.model.dart';
import '../../documents/models/attributes/attributes.model.dart';
import '../../documents/models/change-source.enum.dart';
import '../../documents/models/nodes/block.model.dart';
import '../../documents/models/nodes/line.model.dart';
import '../../documents/models/nodes/node.model.dart';
import '../../shared/models/editable-box-renderer.model.dart';
import '../../shared/state/editor.state.dart';
import '../../visual-editor.dart';
import '../models/link-action-menu.enum.dart';
import '../models/vertical-spacing.model.dart';
import '../widgets/editable-text-block-renderer.dart';
import '../widgets/editable-text-line.dart';
import '../widgets/text-line.dart';

class LinesBlocksService {
  static final _instance = LinesBlocksService._privateConstructor();

  factory LinesBlocksService() => _instance;

  LinesBlocksService._privateConstructor();

  EditableTextLine getEditableTextLineFromNode(LineM node, EditorState state) {
    final editor = state.refs.editorState;

    final textLine = TextLine(
      line: node,
      textDirection: editor.textDirection,
      styles: state.styles.styles,
      linkActionPicker: linkActionPicker,
      state: state,
    );

    final editableTextLine = EditableTextLine(
      line: node,
      leading: null,
      body: textLine,
      indentWidth: 0,
      verticalSpacing: getVerticalSpacingForLine(
        node,
        state.styles.styles,
      ),
      textDirection: editor.textDirection,
      textSelection: state.refs.editorController.selection,
      hasFocus: state.refs.focusNode.hasFocus,
      devicePixelRatio: MediaQuery.of(editor.context).devicePixelRatio,
      state: state,
    );

    return editableTextLine;
  }

  // Updates the checkbox positioned at [offset] in document by changing its attribute according to [value].
  void handleCheckboxTap(int offset, bool value, EditorState state) {
    if (!state.editorConfig.config.readOnly) {
      state.scrollAnimation.disableAnimationOnce(true);
      final attribute =
          value ? AttributesAliasesM.checked : AttributesAliasesM.unchecked;

      state.refs.editorController.formatText(offset, 0, attribute);

      // Checkbox tapping causes controller.selection to go to offset 0.
      // Stop toggling those two buttons buttons.
      state.refs.editorController.toolbarButtonToggler = {
        AttributesM.list.key: attribute,
        AttributesM.header.key: AttributesM.header
      };

      // Go back from offset 0 to current selection.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        state.refs.editorController.updateSelection(
          TextSelection.collapsed(offset: offset),
          ChangeSource.LOCAL,
        );
      });
    }
  }

  Future<LinkMenuAction> linkActionPicker(
      NodeM linkNode, EditorState state) async {
    final link = linkNode.style.attributes[AttributesM.link.key]!.value!;
    final linkDelegate = state.editorConfig.config.linkActionPickerDelegate ??
        defaultLinkActionPickerDelegate;

    return linkDelegate(
      state.refs.editorState.context,
      link,
      linkNode,
    );
  }

  // If an EditableTextBlockRenderer is provided it uses it, otherwise it defaults to the EditorRenderer
  EditableBoxRenderer childAtPosition(
    TextPosition position,
    EditorState state, [
    EditableTextBlockRenderer? blockRenderer,
  ]) {
    final renderer = blockRenderer ?? state.refs.renderer;
    assert(renderer.firstChild != null);

    final targetNode = renderer.container
        .queryChild(
          position.offset,
          false,
        )
        .node;
    var targetChild = renderer.firstChild;

    while (targetChild != null) {
      if (targetChild.container == targetNode) {
        break;
      }

      final newChild = renderer.childAfter(targetChild);

      if (newChild == null) {
        break;
      }

      targetChild = newChild;
    }

    if (targetChild == null) {
      throw 'targetChild should not be null';
    }

    return targetChild;
  }

  // Returns child of this container located at the specified local `offset`.
  // If `offset` is above this container (offset.dy is negative) returns the first child.
  // Likewise, if `offset` is below this container then returns the last child.
  // If an EditableTextBlockRenderer is provided it uses it, otherwise it defaults to the EditorRenderer
  EditableBoxRenderer childAtOffset(
    Offset offset,
    EditorState state, [
    EditableTextBlockRenderer? blockRenderer,
  ]) {
    final renderer = blockRenderer ?? state.refs.renderer;
    assert(renderer.firstChild != null);

    renderer.resolvePadding();

    if (offset.dy <= renderer.resolvedPadding!.top) {
      return renderer.firstChild!;
    }

    if (offset.dy >= renderer.size.height - renderer.resolvedPadding!.bottom) {
      return renderer.lastChild!;
    }

    var child = renderer.firstChild;
    final dx = -offset.dx;
    var dy = renderer.resolvedPadding!.top;

    while (child != null) {
      if (child.size.contains(offset.translate(dx, -dy))) {
        return child;
      }

      dy += child.size.height;
      child = renderer.childAfter(child);
    }

    throw StateError('No child at offset $offset.');
  }

  // Returns the local coordinates of the endpoints of the given selection.
  // If the selection is collapsed (and therefore occupies a single point), the returned list is of length one.
  // Otherwise, the selection is not collapsed and the returned list is of length two.
  // In this case, however, the two points might actually be co-located (e.g., because of a bidirectional
  // selection that contains some text but whose ends meet in the middle).
  TextPosition getPositionForOffset(Offset offset, EditorState state) {
    final local = state.refs.renderer.globalToLocal(offset);
    final child = childAtOffset(local, state);
    final parentData = child.parentData as BoxParentData;
    final localOffset = local - parentData.offset;
    final localPosition = child.getPositionForOffset(localOffset);

    return TextPosition(
      offset: localPosition.offset + child.container.offset,
      affinity: localPosition.affinity,
    );
  }

  double preferredLineHeight(TextPosition position, EditorState state) {
    final child = childAtPosition(position, state);

    return child.preferredLineHeight(
      TextPosition(offset: position.offset - child.container.offset),
    );
  }

  VerticalSpacing getVerticalSpacingForBlock(
    BlockM node,
    EditorStylesM? defaultStyles,
  ) {
    final attrs = node.style.attributes;

    if (attrs.containsKey(AttributesM.blockQuote.key)) {
      return defaultStyles!.quote!.verticalSpacing;
    } else if (attrs.containsKey(AttributesM.codeBlock.key)) {
      return defaultStyles!.code!.verticalSpacing;
    } else if (attrs.containsKey(AttributesM.indent.key)) {
      return defaultStyles!.indent!.verticalSpacing;
    } else if (attrs.containsKey(AttributesM.list.key)) {
      return defaultStyles!.lists!.verticalSpacing;
    } else if (attrs.containsKey(AttributesM.align.key)) {
      return defaultStyles!.align!.verticalSpacing;
    }

    return VerticalSpacing(top: 0, bottom: 0);
  }

  VerticalSpacing getVerticalSpacingForLine(
    LineM line,
    EditorStylesM? defaultStyles,
  ) {
    final attrs = line.style.attributes;

    if (attrs.containsKey(AttributesM.header.key)) {
      final int? level = attrs[AttributesM.header.key]!.value;
      switch (level) {
        case 1:
          return defaultStyles!.h1!.verticalSpacing;
        case 2:
          return defaultStyles!.h2!.verticalSpacing;
        case 3:
          return defaultStyles!.h3!.verticalSpacing;
        default:
          throw 'Invalid level $level';
      }
    }

    return defaultStyles!.paragraph!.verticalSpacing;
  }
}
