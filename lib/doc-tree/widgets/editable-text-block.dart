import 'package:flutter/material.dart';

import '../../document/models/attributes/attributes-aliases.model.dart';
import '../../document/models/attributes/attributes.model.dart';
import '../../document/models/nodes/block.model.dart';
import '../../document/models/nodes/line.model.dart';
import '../../document/services/delta.utils.dart';
import '../../document/services/nodes/node.utils.dart';
import '../../highlights/models/highlight.model.dart';
import '../../links/models/link-action.picker.type.dart';
import '../../markers/models/marker.model.dart';
import '../../shared/state/editor.state.dart';
import '../../styles/models/cfg/editor-styles.model.dart';
import '../models/vertical-spacing.model.dart';
import '../services/lines/text-block.utils.dart';
import '../style-widgets.dart';
import 'editable-text-block-widget-renderer.dart';
import 'editable-text-line-widget-renderer.dart';
import 'text-line.dart';

final _textBlockUtils = TextBlockUtils();

// Renders a list of lines all part of a block.
// Lines have leading (number, bullet, checkbox) and body (text).
// ignore: must_be_immutable
class EditableTextBlock extends StatelessWidget {
  final _du = DeltaUtils();
  final _nodeUtils = NodeUtils();

  final BlockM block;
  final TextDirection textDirection;
  final VerticalSpacing verticalSpacing;
  final TextSelection textSelection;
  final List<HighlightM> highlights;
  final List<HighlightM> hoveredHighlights;
  final List<MarkerM> hoveredMarkers;
  final EditorStylesM? styles;
  final bool hasFocus;
  bool isCodeBlock = false;
  final LinkActionPicker linkActionPicker;
  final Map<int, int> indentLevelCounts;
  final Function(int, bool) onCheckboxTap;
  late EditorState _state;

  EditableTextBlock({
    required this.block,
    required this.textDirection,
    required this.verticalSpacing,
    required this.textSelection,
    required this.highlights,
    required this.hoveredHighlights,
    required this.hoveredMarkers,
    required this.styles,
    required this.hasFocus,
    required this.isCodeBlock,
    required this.linkActionPicker,
    required this.indentLevelCounts,
    required this.onCheckboxTap,
    required EditorState state,
    Key? key,
  }) {
    _cacheStateStore(state);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    return _editableTextBlockWidgetRenderer(
      children: _blockLines(context, indentLevelCounts),
      context: context,
    );
  }

  EditableTextBlockWidgetRenderer _editableTextBlockWidgetRenderer({
    required List<Widget> children,
    required BuildContext context,
  }) {
    final styles = _state.styles.styles;

    return EditableTextBlockWidgetRenderer(
      block: block,
      textDirection: textDirection,
      padding: verticalSpacing,
      decoration: _getBlockDecoration(block, styles) ?? const BoxDecoration(),
      isCodeBlock: isCodeBlock,
      state: _state,
      children: _blockLines(context, indentLevelCounts),
    );
  }

  BoxDecoration? _getBlockDecoration(
    BlockM node,
    EditorStylesM? defaultStyles,
  ) {
    final attrs = block.style.attributes;

    if (attrs.containsKey(AttributesM.blockQuote.key)) {
      return defaultStyles!.quote!.decoration;
    }

    if (attrs.containsKey(AttributesM.codeBlock.key)) {
      return defaultStyles!.code!.decoration;
    }

    return null;
  }

  List<Widget> _blockLines(
    BuildContext context,
    Map<int, int> indents,
  ) {
    final styles = _state.styles.styles;
    final count = block.children.length;
    final children = <Widget>[];
    var index = 0;

    for (final line in Iterable.castFrom<dynamic, LineM>(block.children)) {
      index++;

      final editableTextLine = EditableTextLineWidgetRenderer(
        line: line,
        leading: _lineLeadingEl(
          context,
          line,
          index,
          indents,
          count,
        ),
        underlyingText: TextLine(
          line: line,
          textDirection: textDirection,
          styles: styles,
          linkActionPicker: linkActionPicker,
          state: _state,
        ),
        indentWidth: _textBlockUtils.getIndentWidth(block),
        verticalSpacing: _textBlockUtils.getSpacingForLine(
          block,
          line,
          index,
          count,
          styles,
        ),
        textDirection: textDirection,
        textSelection: textSelection,
        highlights: highlights,
        hoveredHighlights: hoveredHighlights,
        hoveredMarkers: hoveredMarkers,
        hasFocus: hasFocus,
        devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
        state: _state,
      );

      final nodeTextDirection = _du.getDirectionOfNode(line);

      children.add(
        Directionality(
          textDirection: nodeTextDirection,
          child: editableTextLine,
        ),
      );
    }

    return children.toList(
      growable: false,
    );
  }

  // Lines that are part of doc-tree might have also a dedicated content type
  Widget? _lineLeadingEl(
    BuildContext context,
    LineM line,
    int index,
    Map<int, int> indentLevelCounts,
    int count,
  ) {
    final styles = _state.styles.styles;
    final attrs = line.style.attributes;

    // Numbered list
    if (attrs[AttributesM.list.key] == AttributesAliasesM.orderedList) {
      return NumberPoint(
        blockLength: count,
        indentLevelCounts: indentLevelCounts,
        textStyle: styles.leading!.style,
        attrs: attrs,
        containerWidth: 32,
        endPadding: 8,
      );
    }

    // Bullet
    if (attrs[AttributesM.list.key] == AttributesAliasesM.bulletList) {
      return BulletPoint(
        style: styles.leading!.style.copyWith(
          fontWeight: FontWeight.bold,
        ),
        width: 32,
      );
    }

    final lineOffset = _nodeUtils.getDocumentOffset(line);

    // Checked
    if (attrs[AttributesM.list.key] == AttributesAliasesM.checked) {
      return CheckboxPoint(
        size: 14,
        value: true,
        enabled: !_state.config.readOnly,
        onChanged: (checked) => onCheckboxTap(lineOffset, checked),
        uiBuilder: styles.lists?.checkboxUIBuilder,
      );
    }

    // Unchecked
    if (attrs[AttributesM.list.key] == AttributesAliasesM.unchecked) {
      return CheckboxPoint(
        size: 14,
        value: false,
        enabled: !_state.config.readOnly,
        onChanged: (checked) => onCheckboxTap(lineOffset, checked),
        uiBuilder: styles.lists?.checkboxUIBuilder,
      );
    }

    // Code Block
    if (attrs.containsKey(AttributesM.codeBlock.key)) {
      return NumberPoint(
        blockLength: count,
        indentLevelCounts: indentLevelCounts,
        textStyle: styles.code!.style.copyWith(
          color: styles.code!.style.color!.withOpacity(0.4),
        ),
        containerWidth: 32,
        attrs: attrs,
        endPadding: 16,
        hasDotAfterNumber: false,
      );
    }

    return null;
  }

  // === UTILS ===

  void _cacheStateStore(EditorState state) {
    _state = state;
  }
}
