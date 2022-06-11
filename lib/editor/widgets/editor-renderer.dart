import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../documents/models/document.model.dart';
import '../../editor/widgets/editor-renderer-inner.dart';

class EditorRenderer extends MultiChildRenderObjectWidget {
  final ViewportOffset? offset;
  final DocumentM document;
  final TextDirection textDirection;

  EditorRenderer({
    required Key key,
    required List<Widget> children,
    required this.document,
    required this.textDirection,
    this.offset,
  }) : super(key: key, children: children);

  @override
  EditorRendererInner createRenderObject(BuildContext context) =>
      EditorRendererInner(
        offset: offset,
        document: document,
        textDirection: textDirection,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    EditorRendererInner render,
  ) {
    render.offset = offset;
  }
}
