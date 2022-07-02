import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../shared/state/editor.state.dart';
import 'single-child-viewport.dart';

// Very similar to SingleChildView but with a ViewportBuilder argument instead of a Widget
// Useful when child needs ViewportOffset (e.g. RenderEditor)
// ignore: must_be_immutable
class EditorSingleChildScrollView extends StatelessWidget {
  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  void setState(EditorState state) {
    _state = state;
  }

  // Creates a box in which a single widget can be scrolled.
  EditorSingleChildScrollView({
    required this.viewportBuilder,
    required EditorState state,
    Key? key,
    this.restorationId,
  }) : super(key: key) {
    setState(state);
  }

  // {@macro flutter.widgets.scrollable.restorationId}
  final String? restorationId;

  final ViewportBuilder viewportBuilder;

  AxisDirection _getDirection(BuildContext context) {
    return getAxisDirectionFromAxisReverseAndDirectionality(
      context,
      Axis.vertical,
      false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final axisDirection = _getDirection(context);
    final scrollable = Scrollable(
      axisDirection: axisDirection,
      controller: _state.refs.scrollController,
      physics: _state.editorConfig.config.scrollPhysics,
      restorationId: restorationId,
      viewportBuilder: (context, offset) {
        return SingleChildViewport(
          offset: offset,
          child: viewportBuilder(context, offset),
        );
      },
    );

    return scrollable;
  }
}
