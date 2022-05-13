import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'single-child-viewport-renderer.dart';

class SingleChildViewport extends SingleChildRenderObjectWidget {
  const SingleChildViewport({
    required this.offset,
    Key? key,
    Widget? child,
  }) : super(key: key, child: child);

  final ViewportOffset offset;

  @override
  RenderSingleChildViewport createRenderObject(BuildContext context) {
    return RenderSingleChildViewport(
      offset: offset,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSingleChildViewport renderObject,
  ) {
    // Order dependency: The offset setter reads the axis direction.
    renderObject.offset = offset;
  }
}
