import 'package:flutter/material.dart';
import 'tooltip-triangle.dart';

// Menu with an arrow at the top.
class TooltipMenu extends StatelessWidget {
  final List<Widget> children;

  const TooltipMenu({
    required this.children,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => _stack(
        children: _tooltipPlacementArea(
          child: _menuBox(),
        ),
      );

  Widget _stack({required Widget children}) => Stack(
        children: [
          children,
          Positioned(
            top: 6.9,
            left: 0,
            child: TooltipTriangle(),
          ),
        ],
      );

  Widget _tooltipPlacementArea({required Widget child}) => Container(
        padding: EdgeInsets.only(top: 17.5),
        color: Colors.transparent,
        child: child,
      );

  Widget _menuBox() => Container(
        padding: EdgeInsets.symmetric(
          vertical: 7,
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 5,
              offset: Offset(5, 5),
              blurStyle: BlurStyle.solid,
              spreadRadius: -5,
            ),
          ],
          borderRadius: BorderRadius.all(
            Radius.circular(4),
          ),
          border: Border.all(
            color: Color(0xffcfcdcd),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      );
}
