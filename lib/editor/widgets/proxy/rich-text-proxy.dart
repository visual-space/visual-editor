import 'package:flutter/widgets.dart';

import 'paragraph-proxy-renderer.dart';

// TODO Document Proxy. It's unclear what it does. Bellow is my best current explanation. But it needs to be double checked.
// My best current understanding is that the proxy are extremely important for generating the virtual scrool behavior.
// All the text lines are mapped to text lines proxies.
// These proxies generate RenderObjects.
// Flutter uses RenderObjects to calculate the layout of widgets without rendering them.
// A TextLine proxy uses the known styles of text to approximate the sizes of all render objects.
// Once these sizes are known Flutter can compute the correct position of the visible widgets on screen.
// The scroll position will be computed correctly and only the widgets expected to be visible are rendered in full.
// This greatly improves scroll performance even for large documents (Similar to how listview works).
class RichTextProxy extends SingleChildRenderObjectWidget {
  // Child argument should be an instance of RichText widget.
  const RichTextProxy({
    required RichText child,
    required this.textStyle,
    required this.textAlign,
    required this.textDirection,
    required this.locale,
    required this.strutStyle,
    this.textScaleFactor = 1.0,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    Key? key,
  }) : super(key: key, child: child);

  final TextStyle textStyle;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final double textScaleFactor;
  final Locale locale;
  final StrutStyle strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  @override
  RenderParagraphProxy createRenderObject(BuildContext context) {
    return RenderParagraphProxy(
      null,
      textStyle,
      textAlign,
      textDirection,
      textScaleFactor,
      strutStyle,
      locale,
      textWidthBasis,
      textHeightBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderParagraphProxy renderObject,
  ) {
    renderObject
      ..textStyle = textStyle
      ..textAlign = textAlign
      ..textDirection = textDirection
      ..textScaleFactor = textScaleFactor
      ..locale = locale
      ..strutStyle = strutStyle
      ..textWidthBasis = textWidthBasis
      ..textHeightBehavior = textHeightBehavior;
  }
}
