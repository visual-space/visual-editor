import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controller/services/editor-controller.dart';
import '../../documents/models/attribute.dart';
import '../../documents/models/nodes/leaf.dart';
import '../../documents/models/nodes/leaf.dart' as leaf;
import '../../documents/models/nodes/line.dart';
import '../../documents/models/nodes/node.dart';
import '../../documents/models/style.dart';
import '../../editor/widgets/proxy/embed-proxy.dart';
import '../../editor/widgets/proxy/rich-text-proxy.dart';
import '../../inputs/state/pressed-keys-state.dart';
import '../../shared/utils/color.utils.dart';
import '../../shared/utils/platform.utils.dart';
import '../const/link-prefixes.const.dart';
import '../models/custom-builders.type.dart';
import '../models/link-action-menu.enum.dart';
import '../models/link-action.picker.type.dart';
import '../services/default-styles.utils.dart';
import '../services/link.utils.dart';

class TextLine extends StatefulWidget {
  const TextLine({
    required this.line,
    required this.embedBuilder,
    required this.styles,
    required this.readOnly,
    required this.controller,
    required this.onLaunchUrl,
    required this.linkActionPicker,
    this.textDirection,
    this.customStyleBuilder,
    Key? key,
  }) : super(key: key);

  final Line line;
  final TextDirection? textDirection;
  final EmbedBuilder embedBuilder;
  final DefaultStyles styles;
  final bool readOnly;
  final EditorController controller;
  final CustomStyleBuilder? customStyleBuilder;
  final ValueChanged<String>? onLaunchUrl;
  final LinkActionPicker linkActionPicker;

  @override
  State<TextLine> createState() => _TextLineState();
}

class _TextLineState extends State<TextLine> {
  bool _metaOrControlPressed = false;
  UniqueKey _richTextKey = UniqueKey();
  final _linkRecognizers = <Node, GestureRecognizer>{};
  PressedKeysState? _pressedKeys;

  @override
  void dispose() {
    _pressedKeys?.removeListener(_pressedKeysChanged);
    _linkRecognizers
      ..forEach((key, value) => value.dispose())
      ..clear();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pressedKeys == null) {
      _pressedKeys = PressedKeysState.of(context);
      _pressedKeys!.addListener(_pressedKeysChanged);
    } else {
      _pressedKeys!.removeListener(_pressedKeysChanged);
      _pressedKeys = PressedKeysState.of(context);
      _pressedKeys!.addListener(_pressedKeysChanged);
    }
  }

  @override
  void didUpdateWidget(covariant TextLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readOnly != widget.readOnly) {
      _richTextKey = UniqueKey();
      _linkRecognizers
        ..forEach((key, value) {
          value.dispose();
        })
        ..clear();
    }
  }

  // +++ REFACTOR
  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    if (widget.line.hasEmbed && widget.line.childCount == 1) {
      // For video, it is always single child
      final embed = widget.line.children.single as Embed;

      return EmbedProxy(
        widget.embedBuilder(
          context,
          widget.controller,
          embed,
          widget.readOnly,
        ),
      );
    }

    final textSpan = _getTextSpanForWholeLine(context);
    final strutStyle = StrutStyle.fromTextStyle(textSpan.style!);
    final textAlign = _getTextAlign();
    final child = RichText(
      key: _richTextKey,
      text: textSpan,
      textAlign: textAlign,
      textDirection: widget.textDirection,
      strutStyle: strutStyle,
      textScaleFactor: MediaQuery.textScaleFactorOf(context),
    );

    return RichTextProxy(
        textStyle: textSpan.style!,
        textAlign: textAlign,
        textDirection: widget.textDirection!,
        strutStyle: strutStyle,
        locale: Localizations.localeOf(context),
        child: child);
  }

  void _pressedKeysChanged() {
    final metaOrControlPressed =
        _pressedKeys!.metaPressed || _pressedKeys!.controlPressed;
    if (_metaOrControlPressed != metaOrControlPressed) {
      setState(() {
        _metaOrControlPressed = metaOrControlPressed;
        _richTextKey = UniqueKey();
      });
    }
  }

  bool get canLaunchLinks {
    // In readOnly mode users can launch links
    // by simply tapping (clicking) on them
    if (widget.readOnly) return true;

    // In editing mode it depends on the platform:

    // Desktop platforms (macos, linux, windows):
    // only allow Meta(Control)+Click combinations
    if (isDesktop()) {
      return _metaOrControlPressed;
    }
    // Mobile platforms (ios, android): always allow but we install a
    // long-press handler instead of a tap one. LongPress is followed by a
    // context menu with actions.
    return true;
  }

  InlineSpan _getTextSpanForWholeLine(BuildContext context) {
    final lineStyle = _getLineStyle(widget.styles);
    if (!widget.line.hasEmbed) {
      return _buildTextSpan(widget.styles, widget.line.children, lineStyle);
    }

    // The line could contain more than one Embed & more than one Text
    final textSpanChildren = <InlineSpan>[];
    var textNodes = LinkedList<Node>();
    for (final child in widget.line.children) {
      if (child is Embed) {
        if (textNodes.isNotEmpty) {
          textSpanChildren
              .add(_buildTextSpan(widget.styles, textNodes, lineStyle));
          textNodes = LinkedList<Node>();
        }
        // Here it should be image
        final embed = WidgetSpan(
            child: EmbedProxy(widget.embedBuilder(
                context, widget.controller, child, widget.readOnly)));
        textSpanChildren.add(embed);
        continue;
      }

      // here child is Text node and its value is cloned
      textNodes.add(child.clone());
    }

    if (textNodes.isNotEmpty) {
      textSpanChildren.add(_buildTextSpan(widget.styles, textNodes, lineStyle));
    }

    return TextSpan(style: lineStyle, children: textSpanChildren);
  }

  TextAlign _getTextAlign() {
    final alignment = widget.line.style.attributes[Attribute.align.key];
    if (alignment == Attribute.leftAlignment) {
      return TextAlign.start;
    } else if (alignment == Attribute.centerAlignment) {
      return TextAlign.center;
    } else if (alignment == Attribute.rightAlignment) {
      return TextAlign.end;
    } else if (alignment == Attribute.justifyAlignment) {
      return TextAlign.justify;
    }
    return TextAlign.start;
  }

  TextSpan _buildTextSpan(DefaultStyles defaultStyles, LinkedList<Node> nodes,
      TextStyle lineStyle) {
    if (nodes.isEmpty && kIsWeb) {
      nodes = LinkedList<Node>()..add(leaf.Text('\u{200B}'));
    }
    final children = nodes
        .map((node) =>
            _getTextSpanFromNode(defaultStyles, node, widget.line.style))
        .toList(growable: false);

    return TextSpan(children: children, style: lineStyle);
  }

  TextStyle _getLineStyle(DefaultStyles defaultStyles) {
    var textStyle = const TextStyle();

    if (widget.line.style.containsKey(Attribute.placeholder.key)) {
      return defaultStyles.placeHolder!.style;
    }

    final header = widget.line.style.attributes[Attribute.header.key];
    final m = <Attribute, TextStyle>{
      Attribute.h1: defaultStyles.h1!.style,
      Attribute.h2: defaultStyles.h2!.style,
      Attribute.h3: defaultStyles.h3!.style,
    };

    textStyle = textStyle.merge(m[header] ?? defaultStyles.paragraph!.style);

    // Only retrieve exclusive block format for the line style purpose
    Attribute? block;
    widget.line.style.getBlocksExceptHeader().forEach((key, value) {
      if (Attribute.exclusiveBlockKeys.contains(key)) {
        block = value;
      }
    });

    TextStyle? toMerge;
    if (block == Attribute.blockQuote) {
      toMerge = defaultStyles.quote!.style;
    } else if (block == Attribute.codeBlock) {
      toMerge = defaultStyles.code!.style;
    } else if (block == Attribute.list) {
      toMerge = defaultStyles.lists!.style;
    }

    textStyle = textStyle.merge(toMerge);
    textStyle = _applyCustomAttributes(textStyle, widget.line.style.attributes);

    return textStyle;
  }

  TextStyle _applyCustomAttributes(
      TextStyle textStyle, Map<String, Attribute> attributes) {
    if (widget.customStyleBuilder == null) {
      return textStyle;
    }
    attributes.keys.forEach((key) {
      final attr = attributes[key];
      if (attr != null) {
        /// Custom Attribute
        final customAttr = widget.customStyleBuilder!.call(attr);
        textStyle = textStyle.merge(customAttr);
      }
    });
    return textStyle;
  }

  TextSpan _getTextSpanFromNode(
      DefaultStyles defaultStyles, Node node, Style lineStyle) {
    final textNode = node as leaf.Text;
    final nodeStyle = textNode.style;
    final isLink = nodeStyle.containsKey(Attribute.link.key) &&
        nodeStyle.attributes[Attribute.link.key]!.value != null;

    return TextSpan(
      text: textNode.value,
      style: _getInlineTextStyle(
          textNode, defaultStyles, nodeStyle, lineStyle, isLink),
      recognizer: isLink && canLaunchLinks ? _getRecognizer(node) : null,
      mouseCursor: isLink && canLaunchLinks ? SystemMouseCursors.click : null,
    );
  }

  TextStyle _getInlineTextStyle(leaf.Text textNode, DefaultStyles defaultStyles,
      Style nodeStyle, Style lineStyle, bool isLink) {
    var res = const TextStyle(); // This is inline text style
    final color = textNode.style.attributes[Attribute.color.key];

    <String, TextStyle?>{
      Attribute.bold.key: defaultStyles.bold,
      Attribute.italic.key: defaultStyles.italic,
      Attribute.small.key: defaultStyles.small,
      Attribute.link.key: defaultStyles.link,
      Attribute.underline.key: defaultStyles.underline,
      Attribute.strikeThrough.key: defaultStyles.strikeThrough,
    }.forEach((k, s) {
      if (nodeStyle.values.any((v) => v.key == k)) {
        if (k == Attribute.underline.key || k == Attribute.strikeThrough.key) {
          var textColor = defaultStyles.color;
          if (color?.value is String) {
            textColor = stringToColor(color?.value);
          }
          res = _merge(res.copyWith(decorationColor: textColor),
              s!.copyWith(decorationColor: textColor));
        } else if (k == Attribute.link.key && !isLink) {
          // null value for link should be ignored
          // i.e. nodeStyle.attributes[Attribute.link.key]!.value == null
        } else {
          res = _merge(res, s!);
        }
      }
    });

    if (nodeStyle.containsKey(Attribute.inlineCode.key)) {
      res = _merge(res, defaultStyles.inlineCode!.styleFor(lineStyle));
    }

    final font = textNode.style.attributes[Attribute.font.key];
    if (font != null && font.value != null) {
      res = res.merge(TextStyle(fontFamily: font.value));
    }

    final size = textNode.style.attributes[Attribute.size.key];
    if (size != null && size.value != null) {
      switch (size.value) {
        case 'small':
          res = res.merge(defaultStyles.sizeSmall);
          break;
        case 'large':
          res = res.merge(defaultStyles.sizeLarge);
          break;
        case 'huge':
          res = res.merge(defaultStyles.sizeHuge);
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
            res = res.merge(TextStyle(fontSize: fontSize));
          } else {
            throw 'Invalid size ${size.value}';
          }
      }
    }

    if (color != null && color.value != null) {
      var textColor = defaultStyles.color;
      if (color.value is String) {
        textColor = stringToColor(color.value);
      }
      if (textColor != null) {
        res = res.merge(TextStyle(color: textColor));
      }
    }

    final background = textNode.style.attributes[Attribute.background.key];
    if (background != null && background.value != null) {
      final backgroundColor = stringToColor(background.value);
      res = res.merge(TextStyle(backgroundColor: backgroundColor));
    }

    res = _applyCustomAttributes(res, textNode.style.attributes);
    return res;
  }

  // A system for caching recognizers
  // TODO document why this system was created. It's not obvious from the code.
  // Most likely for perf reasons
  GestureRecognizer _getRecognizer(Node segment) {
    if (_linkRecognizers.containsKey(segment)) {
      return _linkRecognizers[segment]!;
    }

    if (isDesktop() || widget.readOnly) {
      _linkRecognizers[segment] = TapGestureRecognizer()
        ..onTap = () => _tapNodeLink(segment);
    } else {
      _linkRecognizers[segment] = LongPressGestureRecognizer()
        ..onLongPress = () => _longPressLink(segment);
    }
    return _linkRecognizers[segment]!;
  }

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  void _tapNodeLink(Node node) {
    final link = node.style.attributes[Attribute.link.key]!.value;

    _tapLink(link);
  }

  void _tapLink(String? link) {
    if (link == null) {
      return;
    }

    var launchUrl = widget.onLaunchUrl;
    launchUrl ??= _launchUrl;

    link = link.trim();
    if (!linkPrefixes.any(
      (linkPrefix) => link!.toLowerCase().startsWith(linkPrefix),
    )) {
      link = 'https://$link';
    }
    launchUrl(link);
  }

  Future<void> _longPressLink(Node node) async {
    final link = node.style.attributes[Attribute.link.key]!.value!;
    final action = await widget.linkActionPicker(node);
    switch (action) {
      case LinkMenuAction.launch:
        _tapLink(link);
        break;
      case LinkMenuAction.copy:
        // ignore: unawaited_futures
        Clipboard.setData(
          ClipboardData(text: link),
        );
        break;
      case LinkMenuAction.remove:
        final range = getLinkRange(node);
        widget.controller.formatText(
          range.start,
          range.end - range.start,
          Attribute.link,
        );
        break;
      case LinkMenuAction.none:
        break;
    }
  }

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
