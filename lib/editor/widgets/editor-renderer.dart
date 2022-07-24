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

  // Called after the parent setState() was called, thus the editor layout gets built again.
  // We need to pass the latest document.
  // This is because the document is passed via params instead via reference (as in the original Quill code base).
  // This setup is still here because initially it was very confusing to refactor away .
  // the params and to replace them with the references.
  // TODO Review and check if the params can be replaced with refs
  //  such that we have an uniform architecture in the entire codebase.
  @override
  void updateRenderObject(
    BuildContext context,
    EditorRendererInner render,
  ) {
    render
      ..offset = offset
      ..document = document
      ..setContainer(document.root);
  }
}
