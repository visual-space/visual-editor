import 'package:flutter/material.dart';
import 'triangle-clipper.dart';

// A custom widget which has the shape of a triangle, used as a tooltip arrow.
class TooltipTriangle extends StatelessWidget {
  const TooltipTriangle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _tooltipTriangle();
  }

  // TODO Replace all hardcoded values with a var instead.
  Widget _tooltipTriangle() => Stack(
        children: [
          _innerTriangle(),
          Positioned(
            left: (12 - 11.5) / 2,
            right: (12 - 11.5) / 2,
            bottom: -1.5,
            child: _outerTriangle(),
          ),
        ],
      );

  Widget _outerTriangle() => Container(
        margin: EdgeInsets.only(left: 10),
        child: ClipPath(
          clipper: TriangleClipper(),
          child: Container(
            color: Colors.white,
            height: 11.5,
            width: 19,
          ),
        ),
      );

  Widget _innerTriangle() => Container(
        margin: EdgeInsets.only(left: 10),
        child: ClipPath(
          clipper: TriangleClipper(),
          child: Container(
            color: Color(0xffcfcdcd),
            height: 12,
            width: 20,
          ),
        ),
      );
}
