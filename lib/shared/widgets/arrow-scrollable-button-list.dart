import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Scrollable list with arrow indicators.
// The arrow indicators are automatically hidden if the list is not scrollable in the direction of the respective arrow.
class ArrowScrollableButtonList extends StatefulWidget {
  final List<Widget> buttons;

  const ArrowScrollableButtonList({
    required this.buttons,
    Key? key,
  }) : super(key: key);

  @override
  _ArrowScrollableButtonListState createState() =>
      _ArrowScrollableButtonListState();
}

class _ArrowScrollableButtonListState extends State<ArrowScrollableButtonList>
    with WidgetsBindingObserver {
  final ScrollController _controller = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);

    // Listening to the WidgetsBinding instance is necessary so that we can
    // hide the arrows when the window gets a new size and thus the buttons
    // becomes scrollable/unscrollable.
    WidgetsBinding.instance.addObserver(this);

    // Workaround to allow the scroll controller attach to our ListView so that
    // we can detect if overflow arrows need to be shown on init.
    Timer.run(_handleScroll);
  }

  @override
  Widget build(BuildContext context) => _row(
        children: [
          _leftArrow(),
          _scrollableList(
            child: _buttons(),
          ),
          _rightArrow(),
        ],
      );

  @override
  void didChangeMetrics() => _handleScroll();

  @override
  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Row _row({required List<Widget> children}) => Row(
        children: children,
      );

  Widget _leftArrow() => SizedBox(
        width: 8,
        child: Transform.translate(
          // Move the icon a few pixels to center it
          offset: Offset(-5, -3),
          child: _showLeftArrow
              ? const Icon(
                  Icons.arrow_left,
                  size: 18,
                )
              : null,
        ),
      );

  Widget _scrollableList({required Widget child}) => Expanded(
        child: Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              _computeScroll(pointerSignal);
            }
          },
          child: ScrollConfiguration(
            // Remove the glowing effect, as we already have the arrow indicators
            behavior: _ScrollBehavior(),

            // The CustomScrollView is necessary so that the children are not stretched to the height of the buttons,
            // https://bit.ly/3uC3bjI
            child: CustomScrollView(
              scrollDirection: Axis.horizontal,
              controller: _controller,
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: child,
                )
              ],
            ),
          ),
        ),
      );

  Row _buttons() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.buttons,
      );

  Widget _rightArrow() => SizedBox(
        width: 8,
        child: Transform.translate(
          // Move the icon a few pixels to center it
          offset: Offset(-5, -3),
          child: _showRightArrow
              ? const Icon(
                  Icons.arrow_right,
                  size: 18,
                )
              : null,
        ),
      );

  // === UTILS ===

  void _handleScroll() {
    if (!mounted) {
      return;
    }

    setState(() {
      _showLeftArrow =
          _controller.position.minScrollExtent != _controller.position.pixels;
      _showRightArrow =
          _controller.position.maxScrollExtent != _controller.position.pixels;
    });
  }

  // Horizontal scroll does not respond to the mouse wheel since the last flutter update
  // see https://github.com/flutter/flutter/issues/84842
  // We need to move the scroll based on the pointer signal
  // To the current scroll offset we add the scroll delta component received from the pointer signal
  void _computeScroll(PointerScrollEvent pointerSignal) {
    final offsetBelowMaxScrollLimit =
        _controller.offset <= _controller.position.maxScrollExtent;
    final offsetAboveMinScrollLimit =
        _controller.offset >= _controller.position.minScrollExtent;
    final canBeScrolled =
        offsetBelowMaxScrollLimit && offsetAboveMinScrollLimit;

    if (canBeScrolled) {
      final newScrollPosition =
          _controller.offset + pointerSignal.scrollDelta.dy;
      _controller.jumpTo(newScrollPosition);
    }
  }
}

class _ScrollBehavior extends ScrollBehavior {
  // Delete the Material glow effect.
  @override
  Widget buildOverscrollIndicator(
    context,
    child,
    axisDirection,
  ) =>
      child;

  // Draggable scroll for mobile and laptop touchpad
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.unknown,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
      };
}
