import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../documents/models/attribute.model.dart';
import '../../documents/models/nodes/embed.model.dart';
import '../../documents/models/nodes/line.model.dart';
import '../../documents/models/nodes/node.model.dart';
import '../../documents/models/nodes/text.model.dart';
import '../../documents/models/style.model.dart';
import '../../editor/widgets/proxy/embed-proxy.dart';
import '../../editor/widgets/proxy/rich-text-proxy.dart';
import '../../embeds/widgets/default-embed-builder.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/utils/color.utils.dart';
import '../../shared/utils/platform.utils.dart';
import '../const/link-prefixes.const.dart';
import '../models/custom-builders.type.dart';
import '../models/editor-styles.model.dart';
import '../models/link-action-menu.enum.dart';
import '../models/link-action.picker.type.dart';
import '../services/link.utils.dart';

// ignore: must_be_immutable
class TextLine extends StatefulWidget {
  final LineM line;
  final TextDirection? textDirection;
  final EditorStylesM styles;
  final LinkActionPicker linkActionPicker;

  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  void setState(EditorState state) {
    _state = state;
  }

  TextLine({
    required this.line,
    required this.styles,
    required this.linkActionPicker,
    required EditorState state,
    this.textDirection,
    Key? key,
  }) : super(key: key) {
    setState(state);
  }

  @override
  State<TextLine> createState() => _TextLineState();
}

class _TextLineState extends State<TextLine> {

  bool _metaOrControlPressed = false;
  UniqueKey _richTextKey = UniqueKey();
  final _linkRecognizers = <NodeM, GestureRecognizer>{};
  StreamSubscription? _pressedKeysListener;
  late EmbedBuilder _embedBuilder;

  @override
  void initState() {
    _embedBuilder =
        widget._state.editorConfig.config.embedBuilder ?? defaultEmbedBuilder;
    super.initState();
  }

  @override
  void dispose() {
    _pressedKeysListener?.cancel();
    _linkRecognizers
      ..forEach((key, value) => value.dispose())
      ..clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    if (widget.line.hasEmbed && widget.line.childCount == 1) {
      // For video, it is always single child
      final embed = widget.line.children.single as EmbedM;

      return EmbedProxy(
        _embedBuilder(
          context,
          widget._state.refs.editorController,
          embed,
          widget._state.editorConfig.config.readOnly,
        ),
      );
    }

    final textSpan = _getTextSpanForWholeLine(context);
    final strutStyle = StrutStyle.fromTextStyle(textSpan.style!);
    final textAlign = _getTextAlign();

    return RichTextProxy(
      textStyle: textSpan.style!,
      textAlign: textAlign,
      textDirection: widget.textDirection!,
      strutStyle: strutStyle,
      locale: Localizations.localeOf(context),
      child: RichText(
        key: _richTextKey,
        text: textSpan,
        textAlign: textAlign,
        textDirection: widget.textDirection,
        strutStyle: strutStyle,
        textScaleFactor: MediaQuery.textScaleFactorOf(context),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pressedKeysListener?.cancel();
    _pressedKeysListener = widget._state.pressedKeys.pressedKeys$
        .listen((pressedKeys) => _pressedKeysChanged);
  }

  bool get canLaunchLinks {
    // In readOnly mode users can launch links
    // by simply tapping (clicking) on them
    if (widget._state.editorConfig.config.readOnly) return true;

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

  // === PRIVATE ===

  void _pressedKeysChanged() {
    final metaOrControlPressed = widget._state.pressedKeys.metaPressed ||
        widget._state.pressedKeys.controlPressed;
    if (_metaOrControlPressed != metaOrControlPressed) {
      setState(() {
        _metaOrControlPressed = metaOrControlPressed;
        _richTextKey = UniqueKey();
      });
    }
  }

  InlineSpan _getTextSpanForWholeLine(BuildContext context) {
    final lineStyle = _getLineStyle(widget.styles);

    if (!widget.line.hasEmbed) {
      return _buildTextSpan(widget.styles, widget.line.children, lineStyle);
    }

    // The line could contain more than one Embed & more than one Text
    final textSpanChildren = <InlineSpan>[];
    var textNodes = LinkedList<NodeM>();

    for (final child in widget.line.children) {
      if (child is EmbedM) {
        if (textNodes.isNotEmpty) {
          textSpanChildren
              .add(_buildTextSpan(widget.styles, textNodes, lineStyle));
          textNodes = LinkedList<NodeM>();
        }

        // Here it should be image
        final embed = WidgetSpan(
          child: EmbedProxy(
            _embedBuilder(
              context,
              widget._state.refs.editorController,
              child,
              widget._state.editorConfig.config.readOnly,
            ),
          ),
        );
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
    final alignment = widget.line.style.attributes[AttributeM.align.key];

    if (alignment == AttributeM.leftAlignment) {
      return TextAlign.start;
    } else if (alignment == AttributeM.centerAlignment) {
      return TextAlign.center;
    } else if (alignment == AttributeM.rightAlignment) {
      return TextAlign.end;
    } else if (alignment == AttributeM.justifyAlignment) {
      return TextAlign.justify;
    }

    return TextAlign.start;
  }

  TextSpan _buildTextSpan(
    EditorStylesM defaultStyles,
    LinkedList<NodeM> nodes,
    TextStyle lineStyle,
  ) {
    if (nodes.isEmpty && kIsWeb) {
      nodes = LinkedList<NodeM>()..add(TextM('\u{200B}'));
    }

    final children = nodes
        .map(
          (node) => _getTextSpanFromNode(
            defaultStyles,
            node,
            widget.line.style,
          ),
        )
        .toList(growable: false);

    return TextSpan(
      children: children,
      style: lineStyle,
    );
  }

  TextStyle _getLineStyle(EditorStylesM defaultStyles) {
    var textStyle = const TextStyle();

    if (widget.line.style.containsKey(AttributeM.placeholder.key)) {
      return defaultStyles.placeHolder!.style;
    }

    final header = widget.line.style.attributes[AttributeM.header.key];
    final m = <AttributeM, TextStyle>{
      AttributeM.h1: defaultStyles.h1!.style,
      AttributeM.h2: defaultStyles.h2!.style,
      AttributeM.h3: defaultStyles.h3!.style,
    };

    textStyle = textStyle.merge(m[header] ?? defaultStyles.paragraph!.style);

    // Only retrieve exclusive block format for the line style purpose
    AttributeM? block;
    widget.line.style.getBlocksExceptHeader().forEach((key, value) {
      if (AttributeM.exclusiveBlockKeys.contains(key)) {
        block = value;
      }
    });

    TextStyle? toMerge;

    if (block == AttributeM.blockQuote) {
      toMerge = defaultStyles.quote!.style;
    } else if (block == AttributeM.codeBlock) {
      toMerge = defaultStyles.code!.style;
    } else if (block == AttributeM.list) {
      toMerge = defaultStyles.lists!.style;
    }

    textStyle = textStyle.merge(toMerge);
    textStyle = _applyCustomAttributes(textStyle, widget.line.style.attributes);

    return textStyle;
  }

  TextStyle _applyCustomAttributes(
    TextStyle textStyle,
    Map<String, AttributeM> attributes,
  ) {
    if (widget._state.editorConfig.config.customStyleBuilder == null) {
      return textStyle;
    }

    attributes.keys.forEach((key) {
      final attr = attributes[key];

      if (attr != null) {
        // Custom Attribute
        final customAttr =
            widget._state.editorConfig.config.customStyleBuilder!.call(attr);
        textStyle = textStyle.merge(customAttr);
      }
    });

    return textStyle;
  }

  TextSpan _getTextSpanFromNode(
    EditorStylesM defaultStyles,
    NodeM node,
    StyleM lineStyle,
  ) {
    final textNode = node as TextM;
    final nodeStyle = textNode.style;
    final isLink = nodeStyle.containsKey(AttributeM.link.key) &&
        nodeStyle.attributes[AttributeM.link.key]!.value != null;

    return TextSpan(
      text: textNode.value,
      style: _getInlineTextStyle(
        textNode,
        defaultStyles,
        nodeStyle,
        lineStyle,
        isLink,
      ),
      recognizer: isLink && canLaunchLinks ? _getRecognizer(node) : null,
      mouseCursor: isLink && canLaunchLinks ? SystemMouseCursors.click : null,
    );
  }

  TextStyle _getInlineTextStyle(
    TextM textNode,
    EditorStylesM defaultStyles,
    StyleM nodeStyle,
    StyleM lineStyle,
    bool isLink,
  ) {
    var res = const TextStyle(); // This is inline text style
    final color = textNode.style.attributes[AttributeM.color.key];

    <String, TextStyle?>{
      AttributeM.bold.key: defaultStyles.bold,
      AttributeM.italic.key: defaultStyles.italic,
      AttributeM.small.key: defaultStyles.small,
      AttributeM.link.key: defaultStyles.link,
      AttributeM.underline.key: defaultStyles.underline,
      AttributeM.strikeThrough.key: defaultStyles.strikeThrough,
    }.forEach((k, s) {
      if (nodeStyle.values.any((v) => v.key == k)) {
        if (k == AttributeM.underline.key ||
            k == AttributeM.strikeThrough.key) {
          var textColor = defaultStyles.color;

          if (color?.value is String) {
            textColor = stringToColor(color?.value);
          }
          res = _merge(res.copyWith(decorationColor: textColor),
              s!.copyWith(decorationColor: textColor));
        } else if (k == AttributeM.link.key && !isLink) {
          // null value for link should be ignored
          // i.e. nodeStyle.attributes[Attribute.link.key]!.value == null
        } else {
          res = _merge(res, s!);
        }
      }
    });

    if (nodeStyle.containsKey(AttributeM.inlineCode.key)) {
      res = _merge(res, defaultStyles.inlineCode!.styleFor(lineStyle));
    }

    final font = textNode.style.attributes[AttributeM.font.key];

    if (font != null && font.value != null) {
      res = res.merge(TextStyle(fontFamily: font.value));
    }

    final size = textNode.style.attributes[AttributeM.size.key];

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

    final background = textNode.style.attributes[AttributeM.background.key];

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
  GestureRecognizer _getRecognizer(NodeM segment) {
    if (_linkRecognizers.containsKey(segment)) {
      return _linkRecognizers[segment]!;
    }

    if (isDesktop() || widget._state.editorConfig.config.readOnly) {
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

  void _tapNodeLink(NodeM node) {
    final link = node.style.attributes[AttributeM.link.key]!.value;

    _tapLink(link);
  }

  void _tapLink(String? link) {
    if (link == null) {
      return;
    }

    var launchUrl = widget._state.editorConfig.config.onLaunchUrl;
    launchUrl ??= _launchUrl;

    link = link.trim();

    if (!linkPrefixes.any(
      (linkPrefix) => link!.toLowerCase().startsWith(linkPrefix),
    )) {
      link = 'https://$link';
    }

    launchUrl(link);
  }

  Future<void> _longPressLink(NodeM node) async {
    final link = node.style.attributes[AttributeM.link.key]!.value!;
    final action = await widget.linkActionPicker(node, widget._state);

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
        widget._state.refs.editorController.formatText(
          range.start,
          range.end - range.start,
          AttributeM.link,
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
