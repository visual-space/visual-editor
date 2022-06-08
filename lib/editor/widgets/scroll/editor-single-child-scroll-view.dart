import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../controller/state/scroll-controller.state.dart';
import 'single-child-viewport.dart';

// Very similar to SingleChildView but with a ViewportBuilder argument instead of a Widget
// Useful when child needs ViewportOffset (e.g. RenderEditor)
class EditorSingleChildScrollView extends StatelessWidget {
  final _scrollControllerState = ScrollControllerState();

  // Creates a box in which a single widget can be scrolled.
  EditorSingleChildScrollView({
    required this.viewportBuilder,
    Key? key,
    this.physics,
    this.restorationId,
  }) : super(key: key);

  // How the scroll view should respond to user input.
  // For example, determines how the scroll view continues to animate after the user stops dragging the scroll view.
  // Defaults to matching platform conventions.
  final ScrollPhysics? physics;

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
      controller: _scrollControllerState.controller,
      physics: physics,
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
