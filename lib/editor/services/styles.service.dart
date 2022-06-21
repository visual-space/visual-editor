import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../cursor/controllers/cursor.controller.dart';
import '../../cursor/models/cursor-style.model.dart';
import '../../cursor/state/cursor-controller.state.dart';
import '../../shared/utils/platform.utils.dart';
import '../models/cursor-style-cfg.model.dart';
import '../models/platform-dependent-styles.model.dart';
import '../state/editor-config.state.dart';
import '../state/editor-state-widget.state.dart';
import '../state/platform-styles.state.dart';

// Utils used to generate the styles that will be used to render the editor.
class StylesService {
  final _editorStateWidgetState = EditorStateWidgetState();
  final _cursorControllerState = CursorControllerState();
  final _editorConfigState = EditorConfigState();
  final _platformStylesState = PlatformStylesState();

  static final _instance = StylesService._privateConstructor();

  factory StylesService() => _instance;

  StylesService._privateConstructor();

  PlatformDependentStylesM _getPlatformStyles(BuildContext context) {
    final theme = Theme.of(context);
    final selectionTheme = TextSelectionTheme.of(context);
    final isAppleOs = isAppleOS(theme.platform);
    final platformStyles = isAppleOs
        ? _getAppleOsStyles(selectionTheme, context)
        : _getOtherOsStyles(selectionTheme, theme);

    return platformStyles;
  }

  // This method needs access to the build context.
  // It also needs to be executed before the rest of the widgets are built.
  // Therefore we built a condition to execute it only once.
  void getPlatformStylesAndSetCursorControllerOnce(BuildContext context) {
    if (_platformStylesState.isInitialised) {
      return;
    }

    _platformStylesState.setPlatformStyles(
      _getPlatformStyles(context),
    );

    _cursorControllerState.setController(
      CursorController(
        show: ValueNotifier<bool>(_editorConfigState.config.showCursor),
        style: cursorStyle(),
        tickerProvider: _editorStateWidgetState.editor,
      ),
    );
  }

  // === PRIVATE ===

  PlatformDependentStylesM _getOtherOsStyles(
    TextSelectionThemeData selectionTheme,
    ThemeData theme,
  ) {
    final selectionColor = theme.colorScheme.primary.withOpacity(0.40);

    return PlatformDependentStylesM(
      textSelectionControls: materialTextSelectionControls,
      selectionColor: selectionTheme.selectionColor ?? selectionColor,
      cursorStyle: CursorStyleCfgM(
        cursorColor: selectionTheme.cursorColor ?? theme.colorScheme.primary,
        paintCursorAboveText: false,
        cursorOpacityAnimates: false,
      ),
    );
  }

  PlatformDependentStylesM _getAppleOsStyles(
    TextSelectionThemeData selectionTheme,
    BuildContext context,
  ) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final selectionColor = cupertinoTheme.primaryColor.withOpacity(0.40);
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    return PlatformDependentStylesM(
      textSelectionControls: cupertinoTextSelectionControls,
      selectionColor: selectionTheme.selectionColor ?? selectionColor,
      cursorStyle: CursorStyleCfgM(
        cursorColor: selectionTheme.cursorColor ?? cupertinoTheme.primaryColor,
        cursorRadius: const Radius.circular(2),
        cursorOffset: Offset(iOSHorizontalOffset / pixelRatio, 0),
        paintCursorAboveText: true,
        cursorOpacityAnimates: true,
      ),
    );
  }

  CursorStyle cursorStyle() {
    final style = _platformStylesState.styles.cursorStyle;

    return CursorStyle(
      color: style.cursorColor,
      backgroundColor: Colors.grey,
      width: 2,
      radius: style.cursorRadius,
      offset: style.cursorOffset,
      paintAboveText: _editorConfigState.config.paintCursorAboveText ??
          style.paintCursorAboveText,
      opacityAnimates: style.cursorOpacityAnimates,
    );
  }
}
