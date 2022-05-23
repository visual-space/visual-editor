import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../cursor/models/cursor-style.model.dart';
import '../models/cursor-style-cfg.model.dart';
import '../models/editor-cfg.model.dart';
import '../models/platform-dependent-styles-config.model.dart';

// Utils used to generate the styles that will be used to render the editor.
class StylesUtils {
  static final _instance = StylesUtils._privateConstructor();

  factory StylesUtils() => _instance;

  StylesUtils._privateConstructor();

  PlatformDependentStylesCfgM getOtherOsStyles(
    TextSelectionThemeData selectionTheme,
    ThemeData theme,
  ) {
    final selectionColor = theme.colorScheme.primary.withOpacity(0.40);

    return PlatformDependentStylesCfgM(
      textSelectionControls: materialTextSelectionControls,
      selectionColor: selectionTheme.selectionColor ?? selectionColor,
      cursorStyle: CursorStyleCfgM(
        cursorColor: selectionTheme.cursorColor ?? theme.colorScheme.primary,
        paintCursorAboveText: false,
        cursorOpacityAnimates: false,
      ),
    );
  }

  PlatformDependentStylesCfgM getAppleOsStyles(
    TextSelectionThemeData selectionTheme,
    BuildContext context,
  ) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final selectionColor = cupertinoTheme.primaryColor.withOpacity(0.40);
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    return PlatformDependentStylesCfgM(
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

  CursorStyle cursorStyle(CursorStyleCfgM style, EditorCfgM config) =>
      CursorStyle(
        color: style.cursorColor,
        backgroundColor: Colors.grey,
        width: 2,
        radius: style.cursorRadius,
        offset: style.cursorOffset,
        paintAboveText:
            config.paintCursorAboveText ?? style.paintCursorAboveText,
        opacityAnimates: style.cursorOpacityAnimates,
      );
}
