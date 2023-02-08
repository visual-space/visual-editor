import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../document/models/attributes/attributes.model.dart';
import '../../document/models/nodes/embed-node.model.dart';
import '../../document/models/nodes/line.model.dart';
import '../../document/models/nodes/node.model.dart';
import '../../document/models/nodes/style.model.dart';
import '../../document/models/nodes/text.model.dart';
import '../../editor/widgets/proxy/embed-proxy.dart';
import '../../editor/widgets/proxy/rich-text-proxy.dart';
import '../../inputs/services/keyboard.service.dart';
import '../../links/models/link-action.picker.type.dart';
import '../../links/services/links.service.dart';
import '../../shared/state/editor.state.dart';
import '../../styles/models/cfg/editor-styles.model.dart';
import '../services/lines/text-line-styles.service.dart';

// Text lines render text spans as indicated by the new line character "\n".
// Text lines can have multiple styling attributes applied on arbitrary text selections.
// A node is a continuous section of text with uniform styles.
// When a new attribute is found, a new node is generated.
// TextLines are split in nodes.
// Each node is mapped ot a distinct child textSpan with unique styling.
// All the child text spans are then collected in one parent TextSpan (widget).
// In case a line contains embeds the TextLine is split in several TextSpans (Ex: TextSpan, WidgetSpan, TextSpan).
// Proxy wrappers are generated for the parent text span or embeds to improve performance (virtual scroll).
// ignore: must_be_immutable
class TextLine extends StatefulWidget {
  final LineM line;
  final TextDirection? textDirection;
  final EditorStylesM styles;
  final LinkActionPicker linkActionPicker;
  late EditorState _state;

  TextLine({
    required this.line,
    required this.styles,
    required this.linkActionPicker,
    required EditorState state,
    this.textDirection,
    Key? key,
  }) : super(key: key) {
    _cacheStateStore(state);
  }

  @override
  State<TextLine> createState() => _TextLineState();

  void _cacheStateStore(EditorState state) {
    _state = state;
  }
}

class _TextLineState extends State<TextLine> {
  late final KeyboardService _keyboardService;
  late final TextLineStyleService _textLineStylesService;
  late final LinksService _linksService;

  final _linkRecognizers = <NodeM, GestureRecognizer>{};

  @override
  void initState() {
    _keyboardService = KeyboardService(widget._state);
    _textLineStylesService = TextLineStyleService(widget._state);
    _linksService = LinksService(widget._state);
    super.initState();
  }

  @override
  void dispose() {
    _linkRecognizers
      ..forEach((key, value) => value.dispose())
      ..clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final isEmbedOnly = widget.line.hasEmbed && widget.line.childCount == 1;

    return isEmbedOnly ? _embedProxy(context) : _richTextProxy(context);
  }

  // === PRIVATE ===

  EmbedProxy _embedProxy(BuildContext context) {
    final embed = widget.line.children.single as EmbedNodeM;
    final embedBuilder =
        widget._state.refs.embedBuilderController.getBuilderByEmbed(embed);
    final controller = widget._state.refs.controller;
    final readOnly = widget._state.config.readOnly;

    return EmbedProxy(
      embedBuilder(context, controller, embed, readOnly),
    );
  }

  RichTextProxy _richTextProxy(BuildContext context) {
    final textSpan = _textSpanForWholeLine(context);
    final strutStyle = StrutStyle.fromTextStyle(textSpan.style!);
    final textAlign = _textLineStylesService.getTextAlign(widget.line);
    final locale = Localizations.localeOf(context);
    final textScale = MediaQuery.textScaleFactorOf(context);

    return RichTextProxy(
      textStyle: textSpan.style!,
      textAlign: textAlign,
      textDirection: widget.textDirection!,
      strutStyle: strutStyle,
      locale: locale,
      child: RichText(
        text: textSpan,
        textAlign: textAlign,
        textDirection: widget.textDirection,
        strutStyle: strutStyle,
        textScaleFactor: textScale,
      ),
    );
  }

  // Each new line (\n) renders a TextSpan widget.
  // It also splits the text lines if they contain embeds.
  // Ex: TextSpan, WidgetSpan, TextSpan.
  InlineSpan _textSpanForWholeLine(BuildContext context) {
    final lineStyle = _textLineStylesService.getLineStyle(
      widget.styles,
      widget.line,
    );

    // No embeds
    if (!widget.line.hasEmbed) {
      return _textSpanFromNodes(
        widget.styles,
        widget.line.children,
        lineStyle,
      );
    }

    // The line could contain more than one Embed & more than one Text
    final textSpanChildren = <InlineSpan>[];
    var textNodes = LinkedList<NodeM>();

    for (final child in widget.line.children) {
      // If child is embed run the logic to transform text and embeds in a series of text spans
      if (child is EmbedNodeM) {
        // Cache the text nodes from a text line that contains an embed
        if (textNodes.isNotEmpty) {
          // Convert to text spans and add to textspans cache
          textSpanChildren.add(
            _textSpanFromNodes(widget.styles, textNodes, lineStyle),
          );

          // Clear text cache
          textNodes = LinkedList<NodeM>();
        }

        final embedBuilder =
            widget._state.refs.embedBuilderController.getBuilderByEmbed(
          child,
        );

        // Build the embed as a widget span
        // TextSpan allow custom embeds inside the text.
        final embed = WidgetSpan(
          child: EmbedProxy(
            embedBuilder(
              context,
              widget._state.refs.controller,
              child,
              widget._state.config.readOnly,
            ),
          ),
        );

        // Cache the embedded widget
        textSpanChildren.add(embed);

        // Not plain text so skip over the next step
        continue;
      }

      // Accumulate the text nodes until an embed is found (Fewer text spans).
      textNodes.add(child.clone());
    }

    // If no more embeds are found convert the remaining text Nodes into text spans.
    if (textNodes.isNotEmpty) {
      textSpanChildren.add(
        _textSpanFromNodes(widget.styles, textNodes, lineStyle),
      );
    }

    // Return all the child text spans in a parent text span.
    return TextSpan(
      style: lineStyle,
      children: textSpanChildren,
    );
  }

  // A text span containing multiple text span children.
  // Each one configured to match the combination of styling attributes present in a node.
  // If 2 attributes overlap partly it means we get 3 different child text spans (bold, bold-italic, italic).
  TextSpan _textSpanFromNodes(
    EditorStylesM defaultStyles,
    LinkedList<NodeM> nodes,
    TextStyle lineStyle,
  ) {
    if (nodes.isEmpty && kIsWeb) {
      nodes = LinkedList<NodeM>()
        ..add(
          TextM('\u{200B}'),
        );
    }

    final children = nodes
        .map(
          (node) => _getTextSpanFromNode(
            defaultStyles,
            node,
            widget.line.style,
          ),
        )
        .toList(
          growable: false,
        );

    return TextSpan(
      children: children,
      style: lineStyle,
    );
  }

  // Builds a text span with styles and gesture recognizers out of a node.
  TextSpan _getTextSpanFromNode(
    EditorStylesM defaultStyles,
    NodeM node,
    StyleM lineStyle,
  ) {
    final textNode = node as TextM;
    final nodeStyle = textNode.style;
    final isLink = nodeStyle.containsKey(AttributesM.link.key) &&
        nodeStyle.attributes[AttributesM.link.key]!.value != null;
    final canLaunch = _linksService.canLaunchLinks(_metaOrControlPressed);
    final canLaunchLink = isLink && canLaunch;
    final recognizer = canLaunchLink
        ? _linksService.getRecognizer(
            node,
            widget.linkActionPicker,
            _linkRecognizers,
          )
        : null;

    return TextSpan(
      text: textNode.value,
      style: _textLineStylesService.getInlineTextStyle(
        textNode,
        defaultStyles,
        nodeStyle,
        lineStyle,
        isLink,
      ),
      recognizer: recognizer,
      mouseCursor: canLaunchLink ? SystemMouseCursors.click : null,
    );
  }

  bool get _metaOrControlPressed {
    return _keyboardService.metaPressed || _keyboardService.controlPressed;
  }
}
