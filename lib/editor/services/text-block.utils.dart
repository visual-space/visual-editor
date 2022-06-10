import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tuple/tuple.dart';

import '../../controller/state/editor-controller.state.dart';
import '../../documents/models/change-source.enum.dart';
import '../../documents/models/nodes/block.dart';
import '../../documents/models/nodes/line.dart';
import '../../visual-editor.dart';
import '../state/editor-config.state.dart';
import '../state/scrollControllerAnimation.state.dart';

class TextBlockUtils {
  final _editorConfigState = EditorConfigState();
  final _editorControllerState = EditorControllerState();
  final _scrollControllerAnimationState = ScrollControllerAnimationState();

  static final _instance = TextBlockUtils._privateConstructor();

  factory TextBlockUtils() => _instance;

  TextBlockUtils._privateConstructor();

  Tuple2<double, double> getVerticalSpacingForBlock(
    Block node,
    DefaultStyles? defaultStyles,
  ) {
    final attrs = node.style.attributes;

    if (attrs.containsKey(Attribute.blockQuote.key)) {
      return defaultStyles!.quote!.verticalSpacing;
    } else if (attrs.containsKey(Attribute.codeBlock.key)) {
      return defaultStyles!.code!.verticalSpacing;
    } else if (attrs.containsKey(Attribute.indent.key)) {
      return defaultStyles!.indent!.verticalSpacing;
    } else if (attrs.containsKey(Attribute.list.key)) {
      return defaultStyles!.lists!.verticalSpacing;
    } else if (attrs.containsKey(Attribute.align.key)) {
      return defaultStyles!.align!.verticalSpacing;
    }

    return const Tuple2(0, 0);
  }

  Tuple2<double, double> getVerticalSpacingForLine(
    Line line,
    DefaultStyles? defaultStyles,
  ) {
    final attrs = line.style.attributes;

    if (attrs.containsKey(Attribute.header.key)) {
      final int? level = attrs[Attribute.header.key]!.value;
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
  void handleCheckboxTap(int offset, bool value) {
    if (!_editorConfigState.config.readOnly) {
      _scrollControllerAnimationState.disableAnimationOnce(true);
      final attribute = value ? Attribute.checked : Attribute.unchecked;

      _editorControllerState.controller.formatText(offset, 0, attribute);

      // Checkbox tapping causes controller.selection to go to offset 0.
      // Stop toggling those two buttons buttons.
      _editorControllerState.controller.toolbarButtonToggler = {
        Attribute.list.key: attribute,
        Attribute.header.key: Attribute.header
      };

      // Go back from offset 0 to current selection.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _editorControllerState.controller.updateSelection(
            TextSelection.collapsed(offset: offset), ChangeSource.LOCAL);
      });
    }
  }
}
