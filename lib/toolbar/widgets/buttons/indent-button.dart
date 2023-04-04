import 'dart:async';

import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../editor/services/run-build.service.dart';
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
  late final RunBuildService _runBuildService;

  StreamSubscription? _runBuild$L;

  @override
  void initState() {
    _stylesService = StylesService(widget._state);
    _runBuildService = RunBuildService(widget._state);

    super.initState();
    _subscribeToRunBuild();
  }

  @override
  void dispose() {
    _runBuild$L?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIndentEnabled =
        widget._state.disabledButtons.isSelectionIndentEnabled;

    final iconColor = isIndentEnabled
        ? widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color
        : theme.disabledColor;
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
      onPressed: isIndentEnabled
          ? () => _stylesService.indentSelection(widget.isIncrease)
          : null,
    );
  }

  // === UTILS ===

  // In order to update the button state after each selection change check if button is enabled.
  void _subscribeToRunBuild() {
    _runBuild$L = _runBuildService.runBuild$.listen(
          (_) => setState(() {}),
    );
  }
}
