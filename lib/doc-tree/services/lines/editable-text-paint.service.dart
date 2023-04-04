import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../cursor/controllers/cursor.controller.dart';
import '../../../cursor/widgets/cursor-painter.dart';
import '../../../document/models/attributes/attributes.model.dart';
import '../../../document/models/nodes/text.model.dart';
import '../../../document/services/nodes/node.utils.dart';
import '../../../highlights/models/highlight.model.dart';
import '../../../markers/models/marker-type.model.dart';
import '../../../selection/services/selection-renderer.service.dart';
import '../../../shared/state/editor.state.dart';
import '../../models/text-paint-cfg.model.dart';
import '../rectangles.service.dart';

// EditableTextLineBoxRenderer has many overrides concerned with computing the layout dimensions.
// Therefore the painting logic for selection/highlight boxes is better separated here.
// Separating the layout dimensions logic and painting logic helps improves readability and maintainability.
class EditableTextPaintService {
  late final SelectionRendererService _selectionRendererService;
  late final RectanglesService _rectanglesService;
  final _nodeUtils = NodeUtils();

  final EditorState state;
  late CursorController cursorController;

  EditableTextPaintService(this.state) {
    _selectionRendererService = SelectionRendererService(state);
    _rectanglesService = RectanglesService(state);
    cursorController = state.refs.cursorController;
  }

  void paint(TextPaintCfgM cfg) {
    // Leading (bullets, checkboxes)
    if (cfg.leading != null) {
      final parentData = cfg.leading!.parentData as BoxParentData;
      final offset = cfg.offset + parentData.offset;
      cfg.context.paintChild(cfg.leading!, offset);
    }

    if (cfg.underlyingText != null) {
      final parentData = cfg.underlyingText?.parentData as BoxParentData;
      final offset = cfg.offset + parentData.offset;

      // Code
      if (cfg.inlineCodeStyle.backgroundColor != null) {
        for (final node in cfg.line.children) {
          final isInlineCodeOrCodeBlock = node is! TextM || !node.style.containsKey(AttributesM.inlineCode.key);

          if (isInlineCodeOrCodeBlock) {
            continue;
          }

          _rectanglesService.drawRectanglesFromNode(cfg, node, offset);
        }
      }

      // Markers
      if (state.markersVisibility.visibility == true) {
        // Coordinates
        final markers = _rectanglesService.getMarkersToRender(
          offset,
          cfg.line,
          cfg.underlyingText,
        );

        // Draw Markers
        markers.forEach((marker) {
          final markerType = _getMarkerType(marker);
          final isHovered = state.markers.hoveredMarkers.firstWhereOrNull((_marker) => _marker.id == marker.id) != null;

          if (markerType?.isHighlightVisible == true) {
            _rectanglesService.drawRectangles(
              marker.rectangles ?? [],
              offset,
              cfg.context,
              _getMarkerColor(isHovered, markerType),
              Radius.zero,
            );
          }
        });
      }

      // Cursor above text (iOS)
      if (state.refs.focusNode.hasFocus && cursorController.show.value && cfg.containsCursor() && !cursorController.style.paintAboveText) {
        _paintCursor(cfg, offset);
      }

      // TextLine
      // The raw text, no highlights, only TextSpans with styling
      cfg.context.paintChild(cfg.underlyingText as RenderObject, offset);

      // Cursor bellow text (Android)
      if (state.refs.focusNode.hasFocus && cursorController.show.value && cfg.containsCursor() && cursorController.style.paintAboveText) {
        _paintCursor(cfg, offset);
      }

      // Selection
      final containsSel = cfg.lineContainsSelection(cfg.selection);

      if (state.config.enableInteractiveSelection && containsSel) {
        final local = _selectionRendererService.getLocalSelection(
          cfg.line,
          cfg.selection,
          false,
        );
        final selectedRects = cfg.selectedRects ?? cfg.underlyingText?.getBoxesForSelection(local);

        _paintSelection(cfg.context, offset, selectedRects);
      }

      // Highlights
      // TODO Double check if highlights are rendered on top of markers (or the other way around)
      state.highlights.highlights.forEach((highlight) {
        final lineContainsHighlight = cfg.lineContainsSelection(
          highlight.textSelection,
        );

        if (lineContainsHighlight) {
          final local = _selectionRendererService.getLocalSelection(
            cfg.line,
            highlight.textSelection,
            false,
          );
          final _highlightedRects = cfg.underlyingText?.getBoxesForSelection(
                local,
              ) ??
              [];

          _paintHighlights(
            highlight,
            _highlightedRects,
            cfg.context,
            offset,
          );
        }
      });
    }
  }

  // === PRIVATE ===

  // Once a marker is retrieved from the doc we check against the declared markers types.
  MarkerTypeM? _getMarkerType(marker) {
    assert(
      state.markersTypes.markersTypes.isNotEmpty,
      'At least one marker type must be defined',
    );

    final markerType = state.markersTypes.markersTypes.firstWhereOrNull(
      (markerType) => markerType.id == marker.type,
    );

    return markerType;
  }

  Color _getMarkerColor(bool isHovered, MarkerTypeM? markerType) {
    return (isHovered ? markerType?.hoverColor : markerType?.color) ?? Colors.blue.withOpacity(0.1);
  }

  void _paintSelection(
    PaintingContext context,
    Offset offset,
    List<TextBox>? selectedRects,
  ) {
    assert(selectedRects != null);

    final paint = Paint()..color = state.platformStyles.styles.selectionColor;

    for (final box in selectedRects!) {
      context.canvas.drawRect(box.toRect().shift(offset), paint);
    }
  }

  void _paintHighlights(
    HighlightM highlight,
    List<TextBox> highlightedRects,
    PaintingContext context,
    Offset offset,
  ) {
    final isHovered = state.highlights.hoveredHighlights.map((_highlight) => _highlight.id).contains(highlight.id);
    final paint = Paint()..color = isHovered ? highlight.hoverColor : highlight.color;

    if (highlightedRects.isNotEmpty) {
      for (final box in highlightedRects) {
        context.canvas.drawRect(
          box.toRect().shift(offset),
          paint,
        );
      }
    }
  }

  void _paintCursor(
    TextPaintCfgM cfg,
    Offset offset,
  ) {
    final lineOffset = _nodeUtils.getDocumentOffset(cfg.line);
    final cursorTextPost = cursorController.floatingCursorTextPosition.value;
    final position = cursorController.isFloatingCursorActive
        ? TextPosition(
            offset: cursorTextPost!.offset - lineOffset,
            affinity: cursorTextPost.affinity,
          )
        : TextPosition(
            offset: cfg.selection.extentOffset - lineOffset,
            affinity: cfg.selection.base.affinity,
          );

    final cursorPainter = getCursorPainter(cfg);
    cursorPainter.paint(
      cfg.context.canvas,
      offset,
      position,
      cfg.line.hasEmbed,
    );
  }

  CursorPainter getCursorPainter(TextPaintCfgM cfg) => CursorPainter(
        editable: cfg.underlyingText,
        style: cursorController.style,
        prototype: cfg.caretPrototype,
        color: cursorController.isFloatingCursorActive ? cursorController.style.backgroundColor : cursorController.color.value,
        devicePixelRatio: cfg.devicePixelRatio,
      );
}
