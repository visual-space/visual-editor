import 'package:flutter/material.dart' hide SearchBar;

import '../../../search/search-bar.dart';
import '../../../shared/state/editor-state-receiver.dart';
import '../../../shared/state/editor.state.dart';
import '../../../visual-editor.dart';

// ignore: must_be_immutable
class SearchButton extends StatelessWidget with EditorStateReceiver {
  final EditorController controller;
  final IconData icon;
  final double iconSize;

  final EditorIconThemeM? iconTheme;
  final double buttonsSpacing;

  late EditorState _state;

  SearchButton({
    required this.buttonsSpacing,
    required this.icon,
    required this.controller,
    this.iconSize = 40,
    this.iconTheme,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
  }

  @override
  void cacheStateStore(EditorState state) {
    _state = state;
    _initSearchBar();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overlayState = Overlay.of(context);

    final iconColor = iconTheme?.iconUnselectedColor ?? theme.iconTheme.color;
    final iconFillColor =
        iconTheme?.iconUnselectedFillColor ?? theme.canvasColor;

    return IconBtn(
      icon: Icon(
        icon,
        size: iconSize,
        color: iconColor,
      ),
      highlightElevation: 0,
      hoverElevation: 0,
      size: iconSize * 1.77,
      fillColor: iconFillColor,
      borderRadius: iconTheme?.borderRadius ?? 2,
      onPressed: () {
        overlayState.insert(_state.refs.overlayEntry);
      },
      buttonsSpacing: 0,
    );
  }

  // === UTILS ===

  void _initSearchBar() {
    _state.refs.overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        right: 100,
        child: SearchBar(
          state: _state,
          editorController: controller,
        ),
      ),
    );
  }
}
