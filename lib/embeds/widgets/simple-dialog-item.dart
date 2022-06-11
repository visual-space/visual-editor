import 'package:flutter/material.dart';

class SimpleDialogItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onPressed;

  const SimpleDialogItem({
    required this.icon,
    required this.color,
    required this.text,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(
              icon,
              size: 36,
              color: color,
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 16),
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
}
