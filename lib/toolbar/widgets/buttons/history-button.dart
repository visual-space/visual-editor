import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../toolbar.dart';

class HistoryButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final bool undo;
  final EditorController controller;
  final EditorIconThemeM? iconTheme;
  final double buttonsSpacing;

  const HistoryButton({
    required this.icon,
    required this.controller,
    required this.buttonsSpacing,
    required this.undo,
    this.iconSize = defaultIconSize,
    this.iconTheme,
    Key? key,
  }) : super(key: key);

  @override
  _HistoryButtonState createState() => _HistoryButtonState();
}

class _HistoryButtonState extends State<HistoryButton> {
  Color? _iconColor;
  late ThemeData theme;

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    _setIconColor();

    final fillColor =
        widget.iconTheme?.iconUnselectedFillColor ?? theme.canvasColor;
    widget.controller.changes.listen((event) async {
      _setIconColor();
    });

    return IconBtn(
      highlightElevation: 0,
      hoverElevation: 0,
      buttonsSpacing: widget.buttonsSpacing,
      size: widget.iconSize * 1.77,
      icon: _icon(),
      fillColor: fillColor,
      borderRadius: widget.iconTheme?.borderRadius ?? 2,
      onPressed: _changeHistory,
    );
  }

  // === PRIVATE ===

  Widget _icon() => Icon(
        widget.icon,
        size: widget.iconSize,
        color: _iconColor,
      );

  void _setIconColor() {
    if (!mounted) return;

    if (widget.undo) {
      setState(() {
        _iconColor = widget.controller.hasUndo
            ? widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color
            : widget.iconTheme?.disabledIconColor ?? theme.disabledColor;
      });
    } else {
      setState(() {
        _iconColor = widget.controller.hasRedo
            ? widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color
            : widget.iconTheme?.disabledIconColor ?? theme.disabledColor;
      });
    }
  }

  void _changeHistory() {
    if (widget.undo) {
      if (widget.controller.hasUndo) {
        widget.controller.undo();
      }
    } else {
      if (widget.controller.hasRedo) {
        widget.controller.redo();
      }
    }

    _setIconColor();
  }
}
