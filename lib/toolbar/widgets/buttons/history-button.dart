import 'dart:async';

import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../document/controllers/history.controller.dart';
import '../../../editor/services/editor.service.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/state/editor-state-receiver.dart';
import '../../../shared/state/editor.state.dart';
import '../toolbar.dart';

// Navigates through the history states of the document
// ignore: must_be_immutable
class HistoryButton extends StatefulWidget with EditorStateReceiver {
  final IconData icon;
  final double iconSize;
  final bool isUndo;
  final EditorController controller;
  final EditorIconThemeM? iconTheme;
  final double buttonsSpacing;
  late EditorState _state;

  HistoryButton({
    required this.icon,
    required this.controller,
    required this.buttonsSpacing,
    required this.isUndo,
    this.iconSize = defaultIconSize,
    this.iconTheme,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
  }

  @override
  _HistoryButtonState createState() => _HistoryButtonState();

  @override
  void cacheStateStore(EditorState state) {
    _state = state;
  }
}

class _HistoryButtonState extends State<HistoryButton> {
  late final EditorService _editorService;

  Color? _iconColor;
  late ThemeData theme;
  late final StreamSubscription _docChanges$L;

  @override
  void initState() {
    _editorService = EditorService(widget._state);

    _subscribeToDocumentChanges();
    super.initState();
  }

  @override
  void dispose() {
    _docChanges$L.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    _setIconColor();

    final fillColor =
        widget.iconTheme?.iconUnselectedFillColor ?? theme.canvasColor;

    return IconBtn(
      highlightElevation: 0,
      hoverElevation: 0,
      buttonsSpacing: widget.buttonsSpacing,
      size: widget.iconSize * 1.77,
      icon: _icon(),
      fillColor: fillColor,
      borderRadius: widget.iconTheme?.borderRadius ?? 2,
      onPressed: _undoRedoHistory,
    );
  }

  Widget _icon() => Icon(
        widget.icon,
        size: widget.iconSize,
        color: _iconColor,
      );

  // === UTILS ===

  void _subscribeToDocumentChanges() {
    _docChanges$L = _editorService.changes$.listen((event) {
      _setIconColor();
    });
  }

  // Indicates if there are more available history states.
  void _setIconColor() {
    if (!mounted || !_historyControllerInitialised) {
      return;
    }

    setState(() {
      if (widget.isUndo) {
        _iconColor = _getColor(_historyController?.hasUndo ?? false);
      } else {
        _iconColor = _getColor(_historyController?.hasRedo ?? false);
      }
    });
  }

  // Indicates if there are more available history states.
  Color _getColor(bool enabled) => (enabled
      ? widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color
      : widget.iconTheme?.disabledIconColor ?? theme.disabledColor)!;

  // Depending on which button mode this one is it either undoes or redoes
  void _undoRedoHistory() {
    if (widget.isUndo) {
      if (_historyController!.hasUndo) {
        _historyController!.undo();
      }
    } else {
      if (_historyController!.hasRedo) {
        _historyController!.redo();
      }
    }

    _setIconColor();
  }

  // === PRIVATE ===

  HistoryController? get _historyController {
    return widget._state.refs.historyController;
  }

  bool get _historyControllerInitialised {
    return widget._state.refs.historyControllerInitialised == true;
  }
}
