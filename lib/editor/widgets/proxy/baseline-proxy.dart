import 'package:flutter/widgets.dart';

import 'baseline-proxy-renderer.dart';

class BaselineProxy extends SingleChildRenderObjectWidget {
  final TextStyle? textStyle;
  final EdgeInsets? padding;

  const BaselineProxy({
    Key? key,
    Widget? child,
    this.textStyle,
    this.padding,
  }) : super(key: key, child: child);

  @override
  RenderBaselineProxy createRenderObject(BuildContext context) {
    return RenderBaselineProxy(
      null,
      textStyle!,
      padding,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderBaselineProxy renderObject,
  ) {
    renderObject
      ..textStyle = textStyle!
      ..padding = padding!;
  }
}
