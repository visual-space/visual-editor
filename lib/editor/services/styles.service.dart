import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../cursor/controllers/cursor.controller.dart';
import '../../cursor/models/cursor-style.model.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/utils/platform.utils.dart';
import '../models/cursor-style-cfg.model.dart';
import '../models/platform-dependent-styles.model.dart';

// Utils used to generate the styles that will be used to render the editor.
class StylesService {
  static final _instance = StylesService._privateConstructor();

  factory StylesService() => _instance;

  StylesService._privateConstructor();

  // This method needs access to the build context.
  // It also needs to be executed before the rest of the widgets are built.
  // Therefore we built a condition to execute it only once.
  PlatformDependentStylesM initAndCachePlatformStyles(
    BuildContext context,
    EditorState state,
  ) {
    final styles = _getPlatformStyles(context);
    state.platformStyles.setPlatformStyles(styles);
    return styles;
  }

  CursorController initAndCacheCursorController(EditorState state) {
    final readOnly = !state.editorConfig.config.readOnly;

    final controller = CursorController(
      show: ValueNotifier<bool>(readOnly),
      style: cursorStyle(state),
      tickerProvider: state.refs.editorState,
      state: state,
    );

    state.refs.setCursorController(
      controller,
    );

    return controller;
  }

  // === PRIVATE ===

  PlatformDependentStylesM _getPlatformStyles(BuildContext context) {
    final theme = Theme.of(context);
    final selectionTheme = TextSelectionTheme.of(context);
    final isAppleOs = isAppleOS(theme.platform);
    final platformStyles = isAppleOs
        ? _getAppleOsStyles(selectionTheme, context)
        : _getOtherOsStyles(selectionTheme, theme);

    return platformStyles;
  }

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

  CursorStyle cursorStyle(EditorState state) {
    final defaultStyle = state.platformStyles.styles.cursorStyle;
    final paintCursorAboveText = state.editorConfig.config.paintCursorAboveText;

    return CursorStyle(
      color: defaultStyle.cursorColor,
      backgroundColor: Colors.grey,
      width: 2,
      radius: defaultStyle.cursorRadius,
      offset: defaultStyle.cursorOffset,
      paintAboveText: paintCursorAboveText ?? defaultStyle.paintCursorAboveText,
      opacityAnimates: defaultStyle.cursorOpacityAnimates,
    );
  }
}
