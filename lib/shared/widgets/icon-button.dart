import 'package:flutter/material.dart';

// Collides with Flutter IconButton, therefore we used "Btn" instead of "Button"
class IconBtn extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? icon;
  final double size;
  final Color? fillColor;
  final double hoverElevation;
  final double highlightElevation;
  final double borderRadius;
  final double buttonsSpacing;

  const IconBtn({
    required this.onPressed,
    required this.buttonsSpacing,
    this.icon,
    this.size = 40,
    this.fillColor,
    this.hoverElevation = 1,
    this.highlightElevation = 1,
    this.borderRadius = 2,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: buttonsSpacing,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(
          width: size,
          height: size,
        ),
        child: RawMaterialButton(
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          fillColor: fillColor,
          elevation: 0,
          hoverElevation: hoverElevation,
          highlightElevation: hoverElevation,
          onPressed: onPressed,
          child: icon,
        ),
      ),
    );
  }
}
