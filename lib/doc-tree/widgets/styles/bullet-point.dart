import 'package:flutter/material.dart';

class BulletPoint extends StatelessWidget {
  final TextStyle style;
  final double width;

  const BulletPoint({
    required this.style,
    required this.width,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        alignment: AlignmentDirectional.topEnd,
        width: width,
        padding: const EdgeInsetsDirectional.only(
          end: 13,
        ),
        child: Text(
          '•',
          style: style,
        ),
      );
}
