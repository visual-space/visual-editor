import '../../../document/models/attributes/attributes.model.dart';
import '../../../document/models/nodes/block.model.dart';
import '../../../document/models/nodes/line.model.dart';
import '../../../styles/models/cfg/editor-styles.model.dart';
import '../../models/vertical-spacing.model.dart';

class TextBlockUtils {
  double getIndentWidth(BlockM block) {
    final attrs = block.style.attributes;
    final indent = attrs[AttributesM.indent.key];
    var extraIndent = 0.0;

    if (indent != null && indent.value != null) {
      extraIndent = 16.0 * indent.value;
    }

    if (attrs.containsKey(AttributesM.blockQuote.key)) {
      return 16.0 + extraIndent;
    }

    var baseIndent = 0.0;

    if (attrs.containsKey(AttributesM.list.key) ||
        attrs.containsKey(AttributesM.codeBlock.key)) {
      baseIndent = 32.0;
    }

    return baseIndent + extraIndent;
  }

  VerticalSpacing getSpacingForLine(
    BlockM block,
    LineM node,
    int index,
    int count,
    EditorStylesM? defaultStyles,
  ) {
    var top = 0.0, bottom = 0.0;
    final attrs = block.style.attributes;

    if (attrs.containsKey(AttributesM.header.key)) {
      final level = attrs[AttributesM.header.key]!.value;

      switch (level) {
        case 1:
          top = defaultStyles!.h1!.verticalSpacing.top;
          bottom = defaultStyles.h1!.verticalSpacing.bottom;
          break;

        case 2:
          top = defaultStyles!.h2!.verticalSpacing.top;
          bottom = defaultStyles.h2!.verticalSpacing.bottom;
          break;

        case 3:
          top = defaultStyles!.h3!.verticalSpacing.top;
          bottom = defaultStyles.h3!.verticalSpacing.bottom;
          break;

        default:
          throw 'Invalid level $level';
      }
    } else {
      late VerticalSpacing lineSpacing;

      // TODO Convert to switch
      if (attrs.containsKey(AttributesM.blockQuote.key)) {
        lineSpacing = defaultStyles!.quote!.lineSpacing;
      } else if (attrs.containsKey(AttributesM.indent.key)) {
        lineSpacing = defaultStyles!.indent!.lineSpacing;
      } else if (attrs.containsKey(AttributesM.list.key)) {
        lineSpacing = defaultStyles!.lists!.lineSpacing;
      } else if (attrs.containsKey(AttributesM.codeBlock.key)) {
        lineSpacing = defaultStyles!.code!.lineSpacing;
      } else if (attrs.containsKey(AttributesM.align.key)) {
        lineSpacing = defaultStyles!.align!.lineSpacing;
      }

      top = lineSpacing.top;
      bottom = lineSpacing.bottom;
    }

    if (index == 1) {
      top = 0.0;
    }

    if (index == count) {
      bottom = 0.0;
    }

    return VerticalSpacing(
      top: top,
      bottom: bottom,
    );
  }
}
