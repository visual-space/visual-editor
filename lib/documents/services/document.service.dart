import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../blocks/services/lines-blocks.service.dart';
import '../../blocks/widgets/editable-text-line-widget-renderer.dart';
import '../../highlights/models/highlight.model.dart';
import '../../shared/models/selection-rectangles.model.dart';
import '../../shared/state/editor.state.dart';
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
    final docWidgets = <Widget>[];
    final indentLevelCounts = <int, int>{};
    final nodes = document.root.children;
    final renderers = <EditableTextLineWidgetRenderer>[];

    for (final node in nodes) {
      // Line
      if (node is LineM) {
        final renderer = _linesBlocksService.getEditableTextLineFromNode(
          node,
          state,
        );
        renderers.add(renderer);

        docWidgets.add(
          Directionality(
            textDirection: getDirectionOfNode(node),
            child: renderer,
          ),
        );

        // Block
      } else if (node is BlockM) {
        final renderer = _linesBlocksService.getEditableTextBlockFromNode(
          node,
          node.style.attributes!,
          indentLevelCounts,
          state,
        );

        // TODO Unify duplicated code
        docWidgets.add(
          Directionality(
            textDirection: getDirectionOfNode(node),
            child: renderer,
          ),
        );
      }

      // Fail
      else {
        throw StateError('Unreachable.');
      }
    }

    // Cache markers and highlights coordinates in the state store, after the layout was fully built.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _cacheMarkers(state, renderers);
      _cacheHighlights(state, renderers);
      _cacheSelectionRectangles(state, renderers);
      _cacheHeadings(state, renderers);
    });

    return docWidgets;
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

  // === PRIVATE ===

  // TODO Migrate to _linesBlocksService

  void _cacheMarkers(
      EditorState state, List<EditableTextLineWidgetRenderer> renderers) {
    // Clear the old markers
    state.markers.flushAllMarkers();

    // Markers coordinates
    renderers.forEach((renderer) {
      // We will have to prepopulate the list of markers before rendering to be able to group rectangles by markers.
      final markers = renderer.getMarkersWithCoordinates();

      markers.forEach((marker) {
        state.markers.cacheMarker(marker);
      });
    });
  }

  // (!) For highlights that span multiple lines of text we are extracting from
  // each renderer only the rectangles belonging to that particular line.
  void _cacheHighlights(
      EditorState state, List<EditableTextLineWidgetRenderer> renderers) {
    final highlights = <HighlightM>[];

    // Get Rectangles
    state.highlights.highlights.forEach((highlight) {
      final allRectangles = <SelectionRectanglesM>[];

      renderers.forEach((renderer) {
        // Highlight coordinates
        final lineRectangles = renderer.getHighlightCoordinates(highlight);

        if (lineRectangles != null) {
          allRectangles.add(lineRectangles);
        }
      });

      // Clone and extend
      highlights.add(
        highlight.copyWith(
          rectanglesByLines: allRectangles,
        ),
      );
    });

    // Cache in state store
    state.highlights.setHighlights(highlights);
  }

  // (!) For a selection that span multiple lines of text we are extracting from
  // each renderer only the rectangles belonging to that particular line.
  void _cacheSelectionRectangles(
      EditorState state, List<EditableTextLineWidgetRenderer> renderers) {
    // Get Rectangles
    final rectangles = <SelectionRectanglesM>[];

    renderers.forEach((renderer) {
      // Selection coordinates
      final lineRectangles = renderer.getSelectionCoordinates();

      if (lineRectangles != null) {
        rectangles.add(lineRectangles);
      }
    });

    // Cache in state store
    state.selection.setSelectionRectangles(rectangles);
  }

  void _cacheHeadings(
      EditorState state, List<EditableTextLineWidgetRenderer> renderers) {
    // Clear the old headings
    state.headings.removeAllHeadings();

    // Headings offset
    renderers.forEach((renderer) {
      final heading = renderer.getRenderedHeadingCoordinates();

      if (heading != null) {
        state.headings.addHeading(heading);
      }
    });
  }
}
