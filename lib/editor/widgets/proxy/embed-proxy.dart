import 'package:flutter/widgets.dart';

import 'embed-proxy-renderer.dart';

class EmbedProxy extends SingleChildRenderObjectWidget {
  const EmbedProxy(Widget child) : super(child: child);

  @override
  RenderEmbedProxy createRenderObject(BuildContext context) =>
      RenderEmbedProxy(null);
}
