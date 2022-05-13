import 'package:flutter/material.dart';

class MaterialLinkAction extends StatelessWidget {
  const MaterialLinkAction({
    required this.title,
    required this.icon,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        size: theme.iconTheme.size,
        color: theme.colorScheme.onSurface.withOpacity(0.75),
      ),
      title: Text(title),
      onTap: onPressed,
    );
  }
}
