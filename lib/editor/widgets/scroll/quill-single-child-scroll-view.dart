import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'single-child-viewport.dart';

// Very similar to [SingleChildView] but with a [ViewportBuilder] argument instead of a [Widget]
// Useful when child needs [ViewportOffset] (e.g. [RenderEditor])
// see: [SingleChildScrollView]
class QuillSingleChildScrollView extends StatelessWidget {
  // Creates a box in which a single widget can be scrolled.
  const QuillSingleChildScrollView({
    required this.controller,
    required this.viewportBuilder,
    Key? key,
    this.physics,
    this.restorationId,
  }) : super(key: key);

  // An object that can be used to control the position to which this scroll view is scrolled.
  // Must be null if [primary] is true.
  // A [ScrollController] serves several purposes.
  // It can be used to control the initial scroll position (see [ScrollController.initialScrollOffset]).
  // It can be used to control whether the scroll view should automatically
  // save and restore its scroll position in the [PageStorage]
  // (see [ScrollController.keepScrollOffset]).
  // It can be used to read the current scroll position (see [ScrollController.offset]), or change it
  // (see [ScrollController.animateTo]).
  final ScrollController controller;

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
    final scrollController = controller;
    final scrollable = Scrollable(
      axisDirection: axisDirection,
      controller: scrollController,
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
