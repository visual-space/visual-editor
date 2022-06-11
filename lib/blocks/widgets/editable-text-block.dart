import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../../delta/services/delta.utils.dart';
import '../../documents/models/attribute.model.dart';
import '../../documents/models/nodes/block.model.dart';
import '../../documents/models/nodes/line.model.dart';
import '../../editor/state/editor-config.state.dart';
import '../../editor/widgets/document-styles.dart';
import '../models/default-styles.model.dart';
import '../models/link-action.picker.type.dart';
import '../style-widgets.dart';
import 'editable-block.dart';
import 'editable-text-line.dart';
import 'text-line.dart';

// ignore: must_be_immutable
class EditableTextBlock extends StatelessWidget {
  final _editorConfigState = EditorConfigState();

  final BlockM block;
  final TextDirection textDirection;
  final Tuple2 verticalSpacing;
  final TextSelection textSelection;
  final DefaultStyles? styles;
  final bool hasFocus;
  bool isCodeBlock = false;
  final LinkActionPicker linkActionPicker;
  final Map<int, int> indentLevelCounts;
  final Function(int, bool) onCheckboxTap;

  EditableTextBlock({
    required this.block,
    required this.textDirection,
    required this.verticalSpacing,
    required this.textSelection,
    required this.styles,
    required this.hasFocus,
    required this.isCodeBlock,
    required this.linkActionPicker,
    required this.indentLevelCounts,
    required this.onCheckboxTap,
    Key? key,
  });

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    final defaultStyles = DocumentStyles.getStyles(context, false);

    return EditableBlock(
      block: block,
      textDirection: textDirection,
      padding: verticalSpacing as Tuple2<double, double>,
      decoration: _getDecorationForBlock(
            block,
            defaultStyles,
          ) ??
          const BoxDecoration(),
      isCodeBlock: isCodeBlock,
      children: _buildChildren(context, indentLevelCounts),
    );
  }

  BoxDecoration? _getDecorationForBlock(
    BlockM node,
    DefaultStyles? defaultStyles,
  ) {
    final attrs = block.style.attributes;

    if (attrs.containsKey(AttributeM.blockQuote.key)) {
      return defaultStyles!.quote!.decoration;
    }

    if (attrs.containsKey(AttributeM.codeBlock.key)) {
      return defaultStyles!.code!.decoration;
    }

    return null;
  }

  List<Widget> _buildChildren(
    BuildContext context,
    Map<int, int> indentLevelCounts,
  ) {
    final defaultStyles = DocumentStyles.getStyles(context, false);
    final count = block.children.length;
    final children = <Widget>[];
    var index = 0;

    for (final line in Iterable.castFrom<dynamic, LineM>(block.children)) {
      index++;

      final editableTextLine = EditableTextLine(
        line: line,
        leading: _buildLeading(
          context,
          line,
          index,
          indentLevelCounts,
          count,
        ),
        body: TextLine(
          line: line,
          textDirection: textDirection,
          styles: styles!,
          linkActionPicker: linkActionPicker,
        ),
        indentWidth: _getIndentWidth(),
        verticalSpacing: _getSpacingForLine(
          line,
          index,
          count,
          defaultStyles,
        ),
        textDirection: textDirection,
        textSelection: textSelection,
        hasFocus: hasFocus,
        devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
      );

      final nodeTextDirection = getDirectionOfNode(line);

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

  Widget? _buildLeading(
    BuildContext context,
    LineM line,
    int index,
    Map<int, int> indentLevelCounts,
    int count,
  ) {
    final defaultStyles = DocumentStyles.getStyles(context, false);
    final attrs = line.style.attributes;

    if (attrs[AttributeM.list.key] == AttributeM.ol) {
      return NumberPoint(
        index: index,
        indentLevelCounts: indentLevelCounts,
        count: count,
        style: defaultStyles!.leading!.style,
        attrs: attrs,
        width: 32,
        padding: 8,
      );
    }

    if (attrs[AttributeM.list.key] == AttributeM.ul) {
      return BulletPoint(
        style: defaultStyles!.leading!.style.copyWith(
          fontWeight: FontWeight.bold,
        ),
        width: 32,
      );
    }

    if (attrs[AttributeM.list.key] == AttributeM.checked) {
      return CheckboxPoint(
        size: 14,
        value: true,
        enabled: !_editorConfigState.config.readOnly,
        onChanged: (checked) => onCheckboxTap(line.documentOffset, checked),
        uiBuilder: defaultStyles?.lists?.checkboxUIBuilder,
      );
    }

    if (attrs[AttributeM.list.key] == AttributeM.unchecked) {
      return CheckboxPoint(
        size: 14,
        value: false,
        enabled: !_editorConfigState.config.readOnly,
        onChanged: (checked) => onCheckboxTap(line.documentOffset, checked),
        uiBuilder: defaultStyles?.lists?.checkboxUIBuilder,
      );
    }

    if (attrs.containsKey(AttributeM.codeBlock.key)) {
      return NumberPoint(
        index: index,
        indentLevelCounts: indentLevelCounts,
        count: count,
        style: defaultStyles!.code!.style.copyWith(
          color: defaultStyles.code!.style.color!.withOpacity(0.4),
        ),
        width: 32,
        attrs: attrs,
        padding: 16,
        withDot: false,
      );
    }

    return null;
  }

  double _getIndentWidth() {
    final attrs = block.style.attributes;
    final indent = attrs[AttributeM.indent.key];
    var extraIndent = 0.0;

    if (indent != null && indent.value != null) {
      extraIndent = 16.0 * indent.value;
    }

    if (attrs.containsKey(AttributeM.blockQuote.key)) {
      return 16.0 + extraIndent;
    }

    var baseIndent = 0.0;

    if (attrs.containsKey(AttributeM.list.key) ||
        attrs.containsKey(AttributeM.codeBlock.key)) {
      baseIndent = 32.0;
    }

    return baseIndent + extraIndent;
  }

  Tuple2 _getSpacingForLine(
    LineM node,
    int index,
    int count,
    DefaultStyles? defaultStyles,
  ) {
    var top = 0.0, bottom = 0.0;
    final attrs = block.style.attributes;

    if (attrs.containsKey(AttributeM.header.key)) {
      final level = attrs[AttributeM.header.key]!.value;

      switch (level) {
        case 1:
          top = defaultStyles!.h1!.verticalSpacing.item1;
          bottom = defaultStyles.h1!.verticalSpacing.item2;
          break;

        case 2:
          top = defaultStyles!.h2!.verticalSpacing.item1;
          bottom = defaultStyles.h2!.verticalSpacing.item2;
          break;

        case 3:
          top = defaultStyles!.h3!.verticalSpacing.item1;
          bottom = defaultStyles.h3!.verticalSpacing.item2;
          break;

        default:
          throw 'Invalid level $level';
      }
    } else {
      late Tuple2 lineSpacing;
      if (attrs.containsKey(AttributeM.blockQuote.key)) {
        lineSpacing = defaultStyles!.quote!.lineSpacing;
      } else if (attrs.containsKey(AttributeM.indent.key)) {
        lineSpacing = defaultStyles!.indent!.lineSpacing;
      } else if (attrs.containsKey(AttributeM.list.key)) {
        lineSpacing = defaultStyles!.lists!.lineSpacing;
      } else if (attrs.containsKey(AttributeM.codeBlock.key)) {
        lineSpacing = defaultStyles!.code!.lineSpacing;
      } else if (attrs.containsKey(AttributeM.align.key)) {
        lineSpacing = defaultStyles!.align!.lineSpacing;
      }

      top = lineSpacing.item1;
      bottom = lineSpacing.item2;
    }

    if (index == 1) {
      top = 0.0;
    }

    if (index == count) {
      bottom = 0.0;
    }

    return Tuple2(top, bottom);
  }
}
