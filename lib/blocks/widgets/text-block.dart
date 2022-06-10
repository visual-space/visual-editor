import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../../controller/services/editor-controller.dart';
import '../../cursor/services/cursor.controller.dart';
import '../../delta/services/delta.utils.dart';
import '../../documents/models/attribute.dart';
import '../../documents/models/nodes/block.dart';
import '../../documents/models/nodes/line.dart';
import '../models/custom-builders.type.dart';
import '../models/link-action.picker.type.dart';
import '../services/default-styles.utils.dart';
import '../services/editor-styles.utils.dart';
import 'editable-block.dart';
import 'editable-text-line.dart';
import 'style-widgets.dart';
import 'text-line.dart';

class EditableTextBlock extends StatelessWidget {
  const EditableTextBlock({
    required this.block,
    required this.controller,
    required this.textDirection,
    required this.scrollBottomInset,
    required this.verticalSpacing,
    required this.textSelection,
    required this.styles,
    required this.enableInteractiveSelection,
    required this.hasFocus,
    required this.contentPadding,
    required this.embedBuilder,
    required this.linkActionPicker,
    required this.cursorController,
    required this.indentLevelCounts,
    required this.onCheckboxTap,
    required this.readOnly,
    this.onLaunchUrl,
    this.customStyleBuilder,
    Key? key,
  });

  final Block block;
  final EditorController controller;
  final TextDirection textDirection;
  final double scrollBottomInset;
  final Tuple2 verticalSpacing;
  final TextSelection textSelection;
  final DefaultStyles? styles;
  final bool enableInteractiveSelection;
  final bool hasFocus;
  final EdgeInsets? contentPadding;
  final EmbedBuilder embedBuilder;
  final LinkActionPicker linkActionPicker;
  final ValueChanged<String>? onLaunchUrl;
  final CustomStyleBuilder? customStyleBuilder;
  final CursorController cursorController;
  final Map<int, int> indentLevelCounts;
  final Function(int, bool) onCheckboxTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    final defaultStyles = EditorStylesUtils.getStyles(context, false);
    return EditableBlock(
      block: block,
      textDirection: textDirection,
      padding: verticalSpacing as Tuple2<double, double>,
      scrollBottomInset: scrollBottomInset,
      decoration: _getDecorationForBlock(
            block,
            defaultStyles,
          ) ??
          const BoxDecoration(),
      contentPadding: contentPadding,
      children: _buildChildren(context, indentLevelCounts),
    );
  }

  BoxDecoration? _getDecorationForBlock(
      Block node, DefaultStyles? defaultStyles) {
    final attrs = block.style.attributes;
    if (attrs.containsKey(Attribute.blockQuote.key)) {
      return defaultStyles!.quote!.decoration;
    }
    if (attrs.containsKey(Attribute.codeBlock.key)) {
      return defaultStyles!.code!.decoration;
    }
    return null;
  }

  List<Widget> _buildChildren(
    BuildContext context,
    Map<int, int> indentLevelCounts,
  ) {
    final defaultStyles = EditorStylesUtils.getStyles(context, false);
    final count = block.children.length;
    final children = <Widget>[];
    var index = 0;
    for (final line in Iterable.castFrom<dynamic, Line>(block.children)) {
      index++;
      final editableTextLine = EditableTextLine(
        controller: controller,
        line: line,
        leading: _buildLeading(context, line, index, indentLevelCounts, count),
        body: TextLine(
          line: line,
          textDirection: textDirection,
          embedBuilder: embedBuilder,
          customStyleBuilder: customStyleBuilder,
          styles: styles!,
          readOnly: readOnly,
          controller: controller,
          linkActionPicker: linkActionPicker,
          onLaunchUrl: onLaunchUrl,
        ),
        indentWidth: _getIndentWidth(),
        verticalSpacing: _getSpacingForLine(line, index, count, defaultStyles),
        textDirection: textDirection,
        textSelection: textSelection,
        enableInteractiveSelection: enableInteractiveSelection,
        hasFocus: hasFocus,
        devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
        cursorController: cursorController,
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
    Line line,
    int index,
    Map<int, int> indentLevelCounts,
    int count,
  ) {
    final defaultStyles = EditorStylesUtils.getStyles(context, false);
    final attrs = line.style.attributes;

    if (attrs[Attribute.list.key] == Attribute.ol) {
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

    if (attrs[Attribute.list.key] == Attribute.ul) {
      return BulletPoint(
        style: defaultStyles!.leading!.style.copyWith(
          fontWeight: FontWeight.bold,
        ),
        width: 32,
      );
    }

    if (attrs[Attribute.list.key] == Attribute.checked) {
      return CheckboxPoint(
        size: 14,
        value: true,
        enabled: !readOnly,
        onChanged: (checked) => onCheckboxTap(line.documentOffset, checked),
        uiBuilder: defaultStyles?.lists?.checkboxUIBuilder,
      );
    }

    if (attrs[Attribute.list.key] == Attribute.unchecked) {
      return CheckboxPoint(
        size: 14,
        value: false,
        enabled: !readOnly,
        onChanged: (checked) => onCheckboxTap(line.documentOffset, checked),
        uiBuilder: defaultStyles?.lists?.checkboxUIBuilder,
      );
    }

    if (attrs.containsKey(Attribute.codeBlock.key)) {
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
    final indent = attrs[Attribute.indent.key];
    var extraIndent = 0.0;

    if (indent != null && indent.value != null) {
      extraIndent = 16.0 * indent.value;
    }

    if (attrs.containsKey(Attribute.blockQuote.key)) {
      return 16.0 + extraIndent;
    }

    var baseIndent = 0.0;

    if (attrs.containsKey(Attribute.list.key) ||
        attrs.containsKey(Attribute.codeBlock.key)) {
      baseIndent = 32.0;
    }

    return baseIndent + extraIndent;
  }

  Tuple2 _getSpacingForLine(
    Line node,
    int index,
    int count,
    DefaultStyles? defaultStyles,
  ) {
    var top = 0.0, bottom = 0.0;
    final attrs = block.style.attributes;

    if (attrs.containsKey(Attribute.header.key)) {
      final level = attrs[Attribute.header.key]!.value;
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
      if (attrs.containsKey(Attribute.blockQuote.key)) {
        lineSpacing = defaultStyles!.quote!.lineSpacing;
      } else if (attrs.containsKey(Attribute.indent.key)) {
        lineSpacing = defaultStyles!.indent!.lineSpacing;
      } else if (attrs.containsKey(Attribute.list.key)) {
        lineSpacing = defaultStyles!.lists!.lineSpacing;
      } else if (attrs.containsKey(Attribute.codeBlock.key)) {
        lineSpacing = defaultStyles!.code!.lineSpacing;
      } else if (attrs.containsKey(Attribute.align.key)) {
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
