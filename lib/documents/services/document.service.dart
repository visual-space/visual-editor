import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../blocks/services/lines-blocks.service.dart';
import '../../blocks/widgets/editable-text-block.dart';
import '../../controller/state/document.state.dart';
import '../../controller/state/editor-controller.state.dart';
import '../../delta/services/delta.utils.dart';
import '../../editor/state/editor-state-widget.state.dart';
import '../../editor/state/focus-node.state.dart';
import '../models/attribute.model.dart';
import '../models/nodes/block.model.dart';
import '../models/nodes/line.model.dart';

class DocumentService {
  final _editorControllerState = EditorControllerState();
  final _documentState = DocumentState();
  final _editorStateWidgetState = EditorStateWidgetState();
  final _focusNodeState = FocusNodeState();
  final _linesBlocksService = LinesBlocksService();

  static final _instance = DocumentService._privateConstructor();

  factory DocumentService() => _instance;

  DocumentService._privateConstructor();

  List<Widget> docBlocsAndLines() {
    final docElems = <Widget>[];
    final indentLevelCounts = <int, int>{};
    final nodes = _documentState.document.root.children;

    for (final node in nodes) {
      // Line
      if (node is LineM) {
        docElems.add(
          Directionality(
            textDirection: getDirectionOfNode(node),
            child: _linesBlocksService.getEditableTextLineFromNode(
              node,
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
  ) {
    final editor = _editorStateWidgetState.editor;

    return EditableTextBlock(
      block: node,
      textDirection: editor.textDirection,
      verticalSpacing: _linesBlocksService.getVerticalSpacingForBlock(
        node,
        editor.styles,
      ),
      textSelection: _editorControllerState.controller.selection,
      styles: editor.styles,
      hasFocus: _focusNodeState.node.hasFocus,
      isCodeBlock: attrs.containsKey(AttributeM.codeBlock.key),
      linkActionPicker: _linesBlocksService.linkActionPicker,
      indentLevelCounts: indentLevelCounts,
      onCheckboxTap: _linesBlocksService.handleCheckboxTap,
    );
  }
}
