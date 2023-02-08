import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/state/editor-state-receiver.dart';
import '../../../shared/state/editor.state.dart';
import '../../../styles/services/styles.service.dart';
import '../toolbar.dart';

// Moves text to the right or to the left
// ignore: must_be_immutable
class IndentButton extends StatefulWidget with EditorStateReceiver {
  final IconData icon;
  final double iconSize;
  final EditorController controller;
  final bool isIncrease;
  final EditorIconThemeM? iconTheme;
  final double buttonsSpacing;
  late EditorState _state;

  IndentButton({
    required this.icon,
    required this.controller,
    required this.buttonsSpacing,
    required this.isIncrease,
    this.iconSize = defaultIconSize,
    this.iconTheme,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
  }

  @override
  _IndentButtonState createState() => _IndentButtonState();

  @override
  void cacheStateStore(EditorState state) {
    _state = state;
  }
}

class _IndentButtonState extends State<IndentButton> {
  late final StylesService _stylesService;

  @override
  void initState() {
    _stylesService = StylesService(widget._state);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final iconColor =
        widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color;
    final iconFillColor =
        widget.iconTheme?.iconUnselectedFillColor ?? theme.canvasColor;

    return IconBtn(
      highlightElevation: 0,
      hoverElevation: 0,
      size: widget.iconSize * 1.77,
      icon: Icon(
        widget.icon,
        size: widget.iconSize,
        color: iconColor,
      ),
      buttonsSpacing: widget.buttonsSpacing,
      fillColor: iconFillColor,
      borderRadius: widget.iconTheme?.borderRadius ?? 2,
      onPressed: () => _stylesService.indentSelection(widget.isIncrease),
    );
  }
}
