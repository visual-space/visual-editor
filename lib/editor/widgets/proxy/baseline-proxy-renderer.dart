import 'package:flutter/rendering.dart';

class RenderBaselineProxy extends RenderProxyBox {
  RenderBaselineProxy(
    RenderParagraph? child,
    TextStyle textStyle,
    EdgeInsets? padding,
  )   : _prototypePainter = TextPainter(
            text: TextSpan(text: ' ', style: textStyle),
            textDirection: TextDirection.ltr,
            strutStyle:
                StrutStyle.fromTextStyle(textStyle, forceStrutHeight: true)),
        super(child);

  final TextPainter _prototypePainter;

  set textStyle(TextStyle value) {
    if (_prototypePainter.text!.style == value) {
      return;
    }
    _prototypePainter.text = TextSpan(text: ' ', style: value);
    markNeedsLayout();
  }

  EdgeInsets? _padding;

  set padding(EdgeInsets value) {
    if (_padding == value) {
      return;
    }
    _padding = value;
    markNeedsLayout();
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) =>
      _prototypePainter.computeDistanceToActualBaseline(baseline);

  // SEE What happens + _padding?.top;

  @override
  void performLayout() {
    super.performLayout();
    _prototypePainter.layout();
  }
}
