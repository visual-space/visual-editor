import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../document/models/attributes/attribute.model.dart';
import '../../document/models/attributes/attributes-aliases.model.dart';
import '../../document/models/attributes/attributes.model.dart';
import '../../document/models/document.model.dart';
import '../../document/models/history/change-source.enum.dart';
import '../../document/models/nodes/block.model.dart';
import '../../document/models/nodes/line.model.dart';
import '../../document/models/nodes/node.model.dart';
import '../../document/services/delta.utils.dart';
import '../../highlights/models/highlight.model.dart';
import '../../links/models/link-action-menu.enum.dart';
import '../../links/services/default-link-action-picker-delegate.utils.dart';
import '../../selection/services/selection.service.dart';
import '../../shared/models/selection-rectangles.model.dart';
import '../../shared/state/editor.state.dart';
import '../../styles/models/cfg/editor-styles.model.dart';
import '../../styles/services/styles.service.dart';
import '../models/vertical-spacing.model.dart';
import '../widgets/editable-text-block.dart';
import '../widgets/editable-text-line-widget-renderer.dart';
import '../widgets/text-line.dart';

// Provides the widgets of the doc-tree as described by the document.
// Each new breakline represents a new textline, which generates an EditableTextLine widget.
// Inside a text line, each range of text with an unique set of attributes is considered a node.
// For each node the EditableTextLine generate a TextSpan with the currect test style applied.
// These widgets are EditableTextLine or EditableTextBlock.
// Each time changes are made in the document or the state store the editor build()
// will render once again the document tree.
// After the build cycle is complete we are caching rectangles for
// several layers: selection, highlights, markers, headings.
// Provides the callback for handling checkboxes.
class DocTreeService {
  late final StylesService _stylesService;
  late final SelectionService _selectionService;
  final _du = DeltaUtils();

  final EditorState state;

  DocTreeService(this.state) {
    _stylesService = StylesService(state);
    _selectionService = SelectionService(state);
  }

  // Renders all the text elements (lines and blocs) that are visible in the editor.
  // For each node it renders a new rich text widget.
  List<Widget> getDocumentTree({required DocumentM document}) {
    final docWidgets = <Widget>[];
    var indentLevelCounts = <int, int>{};
    final nodes = state.refs.documentController.rootNode.children;
    final renderers = <EditableTextLineWidgetRenderer>[];

    for (final node in nodes) {
      // Line
      if (node is LineM) {
        final renderer = getEditableTextLineFromNode(node);
        renderers.add(renderer);

        docWidgets.add(
          Directionality(
            textDirection: _du.getDirectionOfNode(node),
            child: renderer,
          ),
        );

        // Needs to be reset after each line in order to start with the indentation at the
        // correct index when entering inside another block and not keep the old indexes of the last block inside it.
        indentLevelCounts = <int, int>{};

        // Block
      } else if (node is BlockM) {
        final renderer = getEditableTextBlockFromNode(
          node,
          node.style.attributes,
          indentLevelCounts,
        );

        // TODO Unify duplicated code
        docWidgets.add(
          Directionality(
            textDirection: _du.getDirectionOfNode(node),
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
      _cacheMarkers(renderers);
      _cacheHighlights(renderers);
      _cacheSelectionRectangles(renderers);
      _cacheSelectedLinkRectangles(renderers);
      _cacheHeadings(renderers);
    });

    return docWidgets;
  }

  // Right before rendering the document we want to check if the document is not empty.
  // If empty, we replace it with placeholder content.
  DocumentM getDocOrPlaceholder() {
    final docIsEmpty = state.refs.documentController.isEmpty();
    return docIsEmpty && _placeholder != null ? _placeholderDoc() : _document;
  }

  DocumentM _placeholderDoc() {
    return DocumentM.fromJson(
      jsonDecode(
        '[{'
        '"attributes":{"placeholder":true},'
        '"insert":"${state.config.placeholder}\\n"'
        '}]',
      ),
    );
  }

  // Generates the editable text line widget from a delta document node
  // Nodes are defined in the delta json using new line chars "\n"
  // An editable text line is composed of a underlying text line (text spans)
  // and the editable text line wrapper (which renders text selection, markers and highlights).
  EditableTextLineWidgetRenderer getEditableTextLineFromNode(LineM node) {
    final editor = state.refs.widget;

    // Text spans with text styling from flutter
    final textLine = TextLine(
      line: node,
      textDirection: editor.textDirection,
      styles: state.styles.styles,
      linkActionPicker: _linkActionPicker,
      state: state,
    );

    // Rendering of selection, highlights, markers, etc
    // Selections is custom rendered because we also handle edge cases such as code doc-tree that are not defined in flutter.
    final editableTextLine = EditableTextLineWidgetRenderer(
      line: node,
      leading: null,
      underlyingText: textLine,
      indentWidth: 0,
      verticalSpacing: _getVerticalSpacingForLine(
        node,
        state.styles.styles,
      ),
      textDirection: editor.textDirection,
      textSelection: state.selection.selection,
      highlights: state.highlights.highlights,
      hoveredHighlights: state.highlights.hoveredHighlights,
      hoveredMarkers: state.markers.hoveredMarkers,
      hasFocus: state.refs.focusNode.hasFocus,
      devicePixelRatio: MediaQuery.of(editor.context).devicePixelRatio,
      state: state,
    );

    return editableTextLine;
  }

  Widget getEditableTextBlockFromNode(
    BlockM node,
    Map<String, AttributeM<dynamic>> attributes,
    Map<int, int> indentLevelCounts,
  ) {
    final editor = state.refs.widget;

    return EditableTextBlock(
      block: node,
      textDirection: editor.textDirection,
      verticalSpacing: _getVerticalSpacingForBlock(
        node,
        state.styles.styles,
      ),
      textSelection: state.selection.selection,
      highlights: state.highlights.highlights,
      hoveredHighlights: state.highlights.hoveredHighlights,
      hoveredMarkers: state.markers.hoveredMarkers,
      styles: state.styles.styles,
      hasFocus: state.refs.focusNode.hasFocus,
      isCodeBlock: attributes.containsKey(AttributesM.codeBlock.key),
      linkActionPicker: _linkActionPicker,
      indentLevelCounts: indentLevelCounts,
      onCheckboxTap: _handleCheckboxTap,
      state: state,
    );
  }

  // === PRIVATE ===

  DocumentM get _document {
    return state.document.document;
  }

  String? get _placeholder {
    return state.config.placeholder;
  }

  void _cacheMarkers(List<EditableTextLineWidgetRenderer> renderers) {
    // Clear the old markers
    state.markers.flushAllMarkers();

    // Markers coordinates
    renderers.forEach((renderer) {
      // We will have to prepopulate the list of markers before rendering to be able to group rectangles by markers.
      final markers = renderer.getMarkersWithCoordinates();

      markers.forEach(state.markers.cacheMarker);
    });
  }

  // (!) For highlights that span multiple lines of text we are extracting from
  // each renderer only the rectangles belonging to that particular line.
  void _cacheHighlights(List<EditableTextLineWidgetRenderer> renderers) {
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
    state.highlights.highlights = highlights;
  }

  // (!) For a selection that span multiple lines of text we are extracting from
  // each renderer only the rectangles belonging to that particular line.
  void _cacheSelectionRectangles(
    List<EditableTextLineWidgetRenderer> renderers,
  ) {
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
    state.selection.selectionRectangles = rectangles;
  }

  void _cacheHeadings(List<EditableTextLineWidgetRenderer> renderers) {
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

  VerticalSpacing _getVerticalSpacingForBlock(
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

  VerticalSpacing _getVerticalSpacingForLine(
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

  // Updates the checkbox positioned at [offset] in document by changing its attribute according to [value].
  void _handleCheckboxTap(int offset, bool value) {
    if (!state.config.readOnly) {
      state.scrollAnimation.disabled = true;
      final attribute =
          value ? AttributesAliasesM.checked : AttributesAliasesM.unchecked;

      _stylesService.formatSelectedText(offset, 0, attribute);

      // Checkbox tapping causes text selection to go to offset 0.
      // Stop toggling those two buttons buttons.
      state.toolbar.buttonToggler = {
        AttributesM.list.key: attribute,
        AttributesM.header.key: AttributesM.header
      };

      // Go back from offset 0 to current selection.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _selectionService.cacheSelectionAndRunBuild(
          TextSelection.collapsed(offset: offset),
          ChangeSource.LOCAL,
        );
      });
    }
  }

  Future<LinkMenuAction> _linkActionPicker(NodeM linkNode) async {
    final link = linkNode.style.attributes[AttributesM.link.key]!.value!;
    final linkDelegate = state.config.linkActionPickerDelegate ??
        defaultLinkActionPickerDelegate;

    return linkDelegate(
      state.refs.widget.context,
      link,
      linkNode,
    );
  }

  // Stores the selected link rectangles after build.
  void _cacheSelectedLinkRectangles(
    List<EditableTextLineWidgetRenderer> renderers,
  ) {
    // Get Rectangles
    final rectangles = <SelectionRectanglesM>[];

    renderers.forEach(
      (renderer) {
        // Selected link coordinates
        final linkRectangles = renderer.getSelectedLinkRectangles();

        if (linkRectangles != null) {
          rectangles.add(linkRectangles);
        }
      },
    );

    // Cache in state store
    state.selectedLink.setSelectedLinkRectangles(rectangles);
  }
}
