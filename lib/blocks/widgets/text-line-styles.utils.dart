import 'package:flutter/material.dart';

import '../../documents/models/attribute.model.dart';
import '../../documents/models/attributes/attributes-aliases.model.dart';
import '../../documents/models/attributes/attributes-types.model.dart';
import '../../documents/models/attributes/attributes.model.dart';
import '../../documents/models/nodes/line.model.dart';
import '../../documents/models/nodes/text.model.dart';
import '../../documents/models/style.model.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/utils/color.utils.dart';
import '../models/editor-styles.model.dart';

// Handles applying the styles of delta operations attributes to the generated text spans.
class TextLineStyleUtils {
  // Whole line styles
  // Returns the styles of a text line depending on the attributes encoded in the delta operations.
  // Combines default general styles with the styles of the delta document (node and line).
  TextStyle getLineStyle(
    EditorStylesM defaultStyles,
    LineM line,
    EditorState state,
  ) {
    var textStyle = const TextStyle();
    final hasAttrs = line.style.attributes != null;

    if (hasAttrs) {
      // Placeholder
      if (line.style.containsKey(AttributesM.placeholder.key)) {
        return defaultStyles.placeHolder!.style;
      }

      // Headers
      final header = line.style.attributes![AttributesM.header.key];
      final m = <AttributeM, TextStyle>{
        AttributesAliasesM.h1: defaultStyles.h1!.style,
        AttributesAliasesM.h2: defaultStyles.h2!.style,
        AttributesAliasesM.h3: defaultStyles.h3!.style,
      };

      textStyle = textStyle.merge(m[header] ?? defaultStyles.paragraph!.style);

      // Only retrieve exclusive block format for the line style purpose
      AttributeM? block;
      line.style.getBlocksExceptHeader().forEach((key, value) {
        if (AttributesTypesM.exclusiveBlockKeys.contains(key)) {
          block = value;
        }
      });

      TextStyle? toMerge;

      // Block Quote, Code Block, List
      if (block == AttributesM.blockQuote) {
        toMerge = defaultStyles.quote!.style;
      } else if (block == AttributesM.codeBlock) {
        toMerge = defaultStyles.code!.style;
      } else if (block == AttributesM.list) {
        toMerge = defaultStyles.lists!.style;
      }

      // Custom style attributes
      textStyle = textStyle.merge(toMerge);
      textStyle = applyCustomAttributes(
        textStyle,
        line.style.attributes!,
        state,
      );
    }

    return textStyle;
  }

  // Line fragments styles
  // Returns the styles of a text line depending on the attributes encoded in the delta operations.
  // Combines default general styles with the styles of the delta document (node and line).
  TextStyle getInlineTextStyle(
    TextM textNode,
    EditorStylesM defaultStyles,
    StyleM nodeStyle,
    StyleM lineStyle,
    bool isLink,
    EditorState state,
  ) {
    var inlineStyle = const TextStyle();
    final hasAttrs = textNode.style.attributes != null;
    final color = textNode.style.attributes?[AttributesM.color.key];

    if (hasAttrs) {
      // TODO Isolate to standalone file
      // Copy styles if attribute is present
      <String, TextStyle?>{
        AttributesM.bold.key: defaultStyles.bold,
        AttributesM.italic.key: defaultStyles.italic,
        AttributesM.small.key: defaultStyles.small,
        AttributesM.link.key: defaultStyles.link,
        AttributesM.underline.key: defaultStyles.underline,
        AttributesM.strikeThrough.key: defaultStyles.strikeThrough,
      }.forEach((key, style) {
        final nodeHasAttribute = nodeStyle.values.any(
          (attribute) => attribute.key == key,
        );

        if (nodeHasAttribute) {
          // Underline, Strikethrough
          if (key == AttributesM.underline.key ||
              key == AttributesM.strikeThrough.key) {
            var textColor = defaultStyles.color;

            if (color?.value is String) {
              textColor = stringToColor(color?.value);
            }

            inlineStyle = _merge(
              inlineStyle.copyWith(
                decorationColor: textColor,
              ),
              style!.copyWith(
                decorationColor: textColor,
              ),
            );

            // Link
          } else if (key == AttributesM.link.key && !isLink) {
            // null value for link should be ignored
            // i.e. nodeStyle.attributes[Attribute.link.key]!.value == null

            // Other
          } else {
            inlineStyle = _merge(inlineStyle, style!);
          }
        }
      });

      // Inline code
      if (nodeStyle.containsKey(AttributesM.inlineCode.key)) {
        inlineStyle = _merge(
          inlineStyle,
          defaultStyles.inlineCode!.styleFor(lineStyle),
        );
      }

      // Fonts
      final font = textNode.style.attributes![AttributesM.font.key];

      {
        if (font != null && font.value != null) {
          inlineStyle = inlineStyle.merge(TextStyle(
            fontFamily: font.value,
          ));
        }
      }

      final size = textNode.style.attributes![AttributesM.size.key];

      // Size
      // TODO Review: S, M, H - Seems to be no longer used (unless we want to support legacy)
      if (size != null && size.value != null) {
        switch (size.value) {
          case 'small':
            inlineStyle = inlineStyle.merge(defaultStyles.sizeSmall);
            break;

          case 'large':
            inlineStyle = inlineStyle.merge(defaultStyles.sizeLarge);
            break;

          case 'huge':
            inlineStyle = inlineStyle.merge(defaultStyles.sizeHuge);
            break;

          default:
            double? fontSize;

            if (size.value is double) {
              fontSize = size.value;
            } else if (size.value is int) {
              fontSize = size.value.toDouble();
            } else if (size.value is String) {
              fontSize = double.tryParse(size.value);
            }

            if (fontSize != null) {
              inlineStyle = inlineStyle.merge(TextStyle(fontSize: fontSize));
            } else {
              throw 'Invalid size ${size.value}';
            }
        }
      }

      // Color
      if (color != null && color.value != null) {
        var textColor = defaultStyles.color;

        if (color.value is String) {
          textColor = stringToColor(color.value);
        }

        if (textColor != null) {
          inlineStyle = inlineStyle.merge(
            TextStyle(color: textColor),
          );
        }
      }

      // Background
      final background = textNode.style.attributes![AttributesM.background.key];

      if (background != null && background.value != null) {
        final backgroundColor = stringToColor(background.value);
        inlineStyle = inlineStyle.merge(
          TextStyle(
            backgroundColor: backgroundColor,
          ),
        );
      }

      inlineStyle = applyCustomAttributes(
        inlineStyle,
        textNode.style.attributes!,
        state,
      );
    }
    return inlineStyle;
  }

  TextStyle applyCustomAttributes(
    TextStyle textStyle,
    Map<String, AttributeM> attributes,
    EditorState state,
  ) {
    if (state.editorConfig.config.customStyleBuilder == null) {
      return textStyle;
    }

    attributes.keys.forEach((key) {
      final attr = attributes[key];

      if (attr != null) {
        // Custom Attribute
        final customAttr = state.editorConfig.config.customStyleBuilder!.call(
          attr,
        );
        textStyle = textStyle.merge(customAttr);
      }
    });

    return textStyle;
  }

  TextAlign getTextAlign(LineM line) {
    final alignment = line.style.attributes![AttributesM.align.key];
    final hasAttrs = line.style.attributes != null;

    if (hasAttrs) {
      if (alignment == AttributesAliasesM.leftAlignment) {
        return TextAlign.start;
      } else if (alignment == AttributesAliasesM.centerAlignment) {
        return TextAlign.center;
      } else if (alignment == AttributesAliasesM.rightAlignment) {
        return TextAlign.end;
      } else if (alignment == AttributesAliasesM.justifyAlignment) {
        return TextAlign.justify;
      }
    }

    return TextAlign.start;
  }

  // === PRIVATE ===

  TextStyle _merge(TextStyle a, TextStyle b) {
    final decorations = <TextDecoration?>[];

    if (a.decoration != null) {
      decorations.add(a.decoration);
    }

    if (b.decoration != null) {
      decorations.add(b.decoration);
    }

    return a.merge(b).apply(
          decoration: TextDecoration.combine(
            List.castFrom<dynamic, TextDecoration>(decorations),
          ),
        );
  }
}
