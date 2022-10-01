import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../documents/models/attributes/attributes.model.dart';
import '../../documents/models/nodes/embed.model.dart';
import '../../documents/models/nodes/line.model.dart';
import '../../documents/models/nodes/node.model.dart';
import '../../documents/models/nodes/text.model.dart';
import '../../documents/models/style.model.dart';
import '../../editor/widgets/proxy/embed-proxy.dart';
import '../../editor/widgets/proxy/rich-text-proxy.dart';
import '../../embeds/widgets/default-embed-builder.dart';
import '../../shared/state/editor.state.dart';
import '../models/custom-builders.type.dart';
import '../models/editor-styles.model.dart';
import '../models/link-action.picker.type.dart';
import 'text-line-link.utils.dart';
import 'text-line-styles.utils.dart';

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
  final _textLineStylesUtils = TextLineStyleUtils();
  final _textLineLinkUtils = TextLineLinkUtils();

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
    final isEmbedOnly = widget.line.hasEmbed && widget.line.childCount == 1;

    return isEmbedOnly ? _embedProxy(context) : _richTextProxy(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pressedKeysListener?.cancel();
    _pressedKeysListener = widget._state.pressedKeys.pressedKeys$.listen(
      (pressedKeys) => _pressedKeysChanged(),
    );
  }

  EmbedProxy _embedProxy(BuildContext context) {
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



  RichTextProxy _richTextProxy(BuildContext context) {
    final textSpan = _textSpanForWholeLine(context);
    final strutStyle = StrutStyle.fromTextStyle(textSpan.style!);
    final alignment = widget.line.style.attributes[AttributesM.align.key];
    final textAlign = _textLineStylesUtils.getTextAlign(alignment,widget.textDirection);

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

  // Each new line (\n) renders a TextSpan widget.
  // It also splits the text lines if they contain embeds.
  // Ex: TextSpan, WidgetSpan, TextSpan.
  InlineSpan _textSpanForWholeLine(BuildContext context) {
    final lineStyle = _textLineStylesUtils.getLineStyle(
      widget.styles,
      widget.line,
      widget._state,
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
      // If child is embed run the logic to transform text and embeds in a seris of text spans
      if (child is EmbedM) {
        // Cache the text nodes from a text line that contains an embed
        if (textNodes.isNotEmpty) {
          // Convert to text spans and add to textspans cache
          textSpanChildren.add(
            _textSpanFromNodes(widget.styles, textNodes, lineStyle),
          );

          // Clear text cache
          textNodes = LinkedList<NodeM>();
        }

        // Build the embed as a widget span
        // TextSpan allow custom embeds inside the text.
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
    final canLaunchLink = isLink &&
        _textLineLinkUtils.canLaunchLinks(
          widget._state,
          _metaOrControlPressed,
        );

    return TextSpan(
      text: textNode.value,
      style: _textLineStylesUtils.getInlineTextStyle(
        textNode,
        defaultStyles,
        nodeStyle,
        lineStyle,
        isLink,
        widget._state,
      ),
      recognizer: canLaunchLink
          ? _textLineLinkUtils.getRecognizer(
              node,
              widget._state,
              widget.linkActionPicker,
              _linkRecognizers,
            )
          : null,
      mouseCursor: canLaunchLink ? SystemMouseCursors.click : null,
    );
  }

  // === UTILS ===

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
}
