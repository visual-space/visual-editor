import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../blocks/services/lines-blocks.service.dart';
import '../../blocks/widgets/editable-text-block.dart';
import '../../shared/state/editor.state.dart';
import '../models/attribute.model.dart';
import '../models/nodes/block.model.dart';
import '../models/nodes/line.model.dart';
import 'delta.utils.dart';

// TODO Convert to widget
class DocumentService {
  final _linesBlocksService = LinesBlocksService();

  static final _instance = DocumentService._privateConstructor();

  factory DocumentService() => _instance;

  DocumentService._privateConstructor();

  List<Widget> docBlocsAndLines({required EditorState state}) {
    final docElems = <Widget>[];
    final indentLevelCounts = <int, int>{};
    final nodes = state.document.document.root.children;

    for (final node in nodes) {
      // Line
      if (node is LineM) {
        docElems.add(
          Directionality(
            textDirection: getDirectionOfNode(node),
            child: _linesBlocksService.getEditableTextLineFromNode(
              node,
              state,
            ),
          ),
        );

        // Block
      } else if (node is BlockM) {
        docElems.add(
          Directionality(
            textDirection: getDirectionOfNode(node),
            child: _editableTextBlock(
              node,
              node.style.attributes,
              indentLevelCounts,
              state,
            ),
          ),
        );

        // Fail
      } else {
        throw StateError('Unreachable.');
      }
    }

    return docElems;
  }

  Widget _editableTextBlock(
    BlockM node,
    Map<String, AttributeM<dynamic>> attrs,
    Map<int, int> indentLevelCounts,
    EditorState state,
  ) {
    final editor = state.refs.editorState;

    return EditableTextBlock(
      block: node,
      textDirection: editor.textDirection,
      verticalSpacing: _linesBlocksService.getVerticalSpacingForBlock(
        node,
        editor.styles,
      ),
      textSelection: state.refs.editorController.selection,
      styles: editor.styles,
      hasFocus: state.refs.focusNode.hasFocus,
      isCodeBlock: attrs.containsKey(AttributeM.codeBlock.key),
      linkActionPicker: _linesBlocksService.linkActionPicker,
      indentLevelCounts: indentLevelCounts,
      onCheckboxTap: (offset, value) => _linesBlocksService.handleCheckboxTap(
        offset,
        value,
        state,
      ),
      state: state,
    );
  }
}
