import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../documents/models/document.model.dart';
import '../../editor/widgets/editor-renderer-inner.dart';
import '../../shared/state/editor.state.dart';

// ignore: must_be_immutable
class EditorRenderer extends MultiChildRenderObjectWidget {
  final ViewportOffset? offset;
  final DocumentM document;
  final TextDirection textDirection;

  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  void setState(EditorState state) {
    _state = state;
  }

  EditorRenderer({
    required List<Widget> children,
    required this.document,
    required this.textDirection,
    required EditorState state,
    Key? key,
    this.offset,
  }) : super(key: key, children: children) {
    setState(state);
  }

  @override
  EditorRendererInner createRenderObject(BuildContext context) =>
      EditorRendererInner(
        offset: offset,
        document: document,
        textDirection: textDirection,
        state: _state,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    EditorRendererInner render,
  ) {
    render.offset = offset;
  }
}
