import 'package:flutter/widgets.dart';

import 'paragraph-proxy-renderer.dart';

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
