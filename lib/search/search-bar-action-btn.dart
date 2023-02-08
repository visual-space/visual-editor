import 'package:flutter/material.dart';

class SearchBarActionBtn extends StatefulWidget {
  final Function()? onTap;
  final IconData icon;
  final EdgeInsets? padding;

  const SearchBarActionBtn({
    required this.icon,
    required this.onTap,
    this.padding,
    Key? key,
  }) : super(key: key);

  @override
  State<SearchBarActionBtn> createState() => _SearchBarActionBtnState();
}

class _SearchBarActionBtnState extends State<SearchBarActionBtn> {
  bool _closeBtnHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onHover: (isHovered) {
        setState(() {
          _closeBtnHovered = isHovered;
        });
      },
      onTap: widget.onTap,
      child: Container(
        padding: widget.padding,
        child: Icon(
          widget.icon,
          color: _closeBtnHovered ? Colors.white : Colors.grey,
          size: 18,
        ),
      ),
    );
  }
}
