import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../blocks/services/lines-blocks.service.dart';
import '../../blocks/widgets/editable-text-block.dart';
import '../../shared/state/editor.state.dart';
import '../models/attribute.model.dart';
import '../models/attributes/attributes.model.dart';
import '../models/document.model.dart';
import '../models/nodes/block.model.dart';
import '../models/nodes/line.model.dart';
import 'delta.utils.dart';

// Provides the building blocks of a document (text spans).
class DocumentService {
  final _linesBlocksService = LinesBlocksService();

  static final _instance = DocumentService._privateConstructor();

  factory DocumentService() => _instance;

  DocumentService._privateConstructor();

  // Renders all the text elements (lines and blocs) that are visible in the editor.
  // For each node it renders a new rich text widget.
  List<Widget> documentBlocsAndLines({
    required DocumentM document,
    required EditorState state,
  }) {
    final docElements = <Widget>[];
    final indentLevelCounts = <int, int>{};
    final nodes = document.root.children;

    // We need to collect all markers from all lines only once per document update.
    // Subsequent draw calls that are triggered by the cursor animation will be ignored.
    state.markers.cacheMarkersAfterBuild = true;

    // Clear the old markers
    state.markers.removeAllMarkers();

    for (final node in nodes) {
      // Line
      if (node is LineM) {
        final editableTextLine =
            _linesBlocksService.getEditableTextLineFromNode(node, state);

        docElements.add(
          Directionality(
            textDirection: getDirectionOfNode(node),
            child: editableTextLine,
          ),
        );

        // Cache markers in state store (after layout was fully built)
        SchedulerBinding.instance.addPostFrameCallback((_) {
          final markers = editableTextLine.getRenderedMarkersCoordinates();

          // Cache markers in state store
          markers.forEach((marker) {
            state.markers.addMarker(marker);
          });
        });

        // Block
      } else if (node is BlockM) {
        docElements.add(
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

    // Only the draws triggered by the build() will end up caching markers
    state.markers.cacheMarkersAfterBuild = false;

    return docElements;
  }

  // Right before sending the document to the rendering layer, we want to check if the document is not empty.
  // If the document is empty, we replace it with placeholder content.
  DocumentM getDocOrPlaceholder(EditorState state) =>
      state.document.document.isEmpty() &&
              state.editorConfig.config.placeholder != null
          ? DocumentM.fromJson(
              jsonDecode(
                '[{'
                '"attributes":{"placeholder":true},'
                '"insert":"${state.editorConfig.config.placeholder}\\n"'
                '}]',
              ),
            )
          : state.document.document;

  Widget _editableTextBlock(
    BlockM node,
    Map<String, AttributeM<dynamic>> attributes,
    Map<int, int> indentLevelCounts,
    EditorState state,
  ) {
    final editor = state.refs.editorState;

    return EditableTextBlock(
      block: node,
      textDirection: editor.textDirection,
      verticalSpacing: _linesBlocksService.getVerticalSpacingForBlock(
        node,
        state.styles.styles,
      ),
      textSelection: state.refs.editorController.selection,
      highlights: state.highlights.highlights,
      styles: state.styles.styles,
      hasFocus: state.refs.focusNode.hasFocus,
      isCodeBlock: attributes.containsKey(AttributesM.codeBlock.key),
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
