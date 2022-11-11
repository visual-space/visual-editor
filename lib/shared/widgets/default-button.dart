import 'package:flutter/material.dart';

// Default button used in demo pages
class DefaultButton extends StatelessWidget {
  final String name;
  final EdgeInsets? padding;
  final Function() onPressed;

  const DefaultButton({
    required this.name,
    required this.onPressed,
    this.padding,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Text(name),
      ),
    );
  }
}
