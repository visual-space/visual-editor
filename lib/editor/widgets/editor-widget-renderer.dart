import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../document/models/delta-doc.model.dart';
import '../../editor/widgets/editor-textarea-renderer.dart';
import '../../shared/state/editor.state.dart';

// ignore: must_be_immutable
class EditorWidgetRenderer extends MultiChildRenderObjectWidget {
  final ViewportOffset? offset;
  final DeltaDocM document;
  final TextDirection textDirection;
  late EditorState _state;

  EditorWidgetRenderer({
    required List<Widget> children,
    required this.document,
    required this.textDirection,
    required EditorState state,
    Key? key,
    this.offset,
  }) : super(key: key, children: children) {
    _cacheStateStore(state);
  }

  @override
  EditorTextAreaRenderer createRenderObject(BuildContext context) =>
      EditorTextAreaRenderer(
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
    EditorTextAreaRenderer render,
  ) {
    render
      ..offset = offset
      ..document = document
      ..setContainer(_state.refs.documentController.rootNode);
  }

  void _cacheStateStore(EditorState state) {
    _state = state;
  }
}
