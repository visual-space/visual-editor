import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/state/editor-state-receiver.dart';
import '../../../shared/state/editor.state.dart';
import '../../../styles/services/styles.service.dart';
import '../toolbar.dart';

// Removes text formatting
// ignore: must_be_immutable
class ClearFormatButton extends StatefulWidget with EditorStateReceiver {
  final IconData icon;
  final double iconSize;
  final EditorController controller;
  final EditorIconThemeM? iconTheme;
  final double buttonsSpacing;
  late EditorState _state;

  ClearFormatButton({
    required this.icon,
    required this.buttonsSpacing,
    required this.controller,
    this.iconSize = defaultIconSize,
    this.iconTheme,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
  }

  @override
  _ClearFormatButtonState createState() => _ClearFormatButtonState();

  @override
  void cacheStateStore(EditorState state) {
    _state = state;
  }
}

class _ClearFormatButtonState extends State<ClearFormatButton> {
  late final StylesService _stylesService;

  late Color _iconColor;
  late Color _fillColor;

  @override
  void initState() {
    _stylesService = StylesService(widget._state);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _cacheButtonsColors(theme);

    return IconBtn(
      highlightElevation: 0,
      hoverElevation: 0,
      size: widget.iconSize * iconButtonFactor,
      icon: Icon(
        widget.icon,
        size: widget.iconSize,
        color: _iconColor,
      ),
      buttonsSpacing: widget.buttonsSpacing,
      fillColor: _fillColor,
      borderRadius: widget.iconTheme?.borderRadius ?? 2,
      onPressed: _stylesService.clearSelectionFormatting,
    );
  }

  void _cacheButtonsColors(ThemeData theme) {
    _iconColor =
        widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color!;
    _fillColor = widget.iconTheme?.iconUnselectedFillColor ?? theme.canvasColor;
  }
}
