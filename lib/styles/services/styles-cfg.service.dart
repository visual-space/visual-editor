import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../cursor/controllers/cursor.controller.dart';
import '../../cursor/models/cursor-style.model.dart';
import '../../doc-tree/models/vertical-spacing.model.dart';
import '../../editor/models/platform-dependent-styles.model.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/utils/platform.utils.dart';
import '../models/cfg/cursor-style-cfg.model.dart';
import '../models/cfg/editor-styles.model.dart';
import '../models/doc-tree/inline-code-style.model.dart';
import '../models/doc-tree/list-block-style.model.dart';
import '../models/doc-tree/text-block-style.model.dart';

const VERTICAL_SPACING_EMPTY = VerticalSpacing(top: 0, bottom: 0);
const VERTICAL_BASE_SPACING = VerticalSpacing(top: 6, bottom: 0);

// Utils used to generate the styles that will be used to render the editor.
class StylesCfgService {
  final EditorState state;

  StylesCfgService(this.state);

  // === DEFAULT STYLES ===

  // Defaults styles found in all the editors.
  // Parameters from this style util  should only be altered if
  // the style is applied to all editors.
  // TODO should be called once and cached, then read from the cache (to avoid memory waste).
  EditorStylesM getDefaultStyles(BuildContext context) {
    final themeData = Theme.of(context);
    final defaultTextStyle = DefaultTextStyle.of(context);
    final baseStyle = defaultTextStyle.style.copyWith(
      fontSize: 16,
      height: 1.3,
    );

    final inlineCodeStyle = GoogleFonts.robotoMono(
      color: Colors.blue.shade900.withOpacity(0.9),
      fontSize: 13,
      height: 1.15,
    );

    return EditorStylesM(
      h1: TextBlockStyleM(
        defaultTextStyle.style.copyWith(
          fontSize: 34,
          color: defaultTextStyle.style.color!.withOpacity(0.70),
          height: 1.15,
          fontWeight: FontWeight.w300,
        ),
        VerticalSpacing(top: 16, bottom: 0),
        VERTICAL_SPACING_EMPTY,
        VERTICAL_SPACING_EMPTY,
        null,
      ),
      h2: TextBlockStyleM(
        defaultTextStyle.style.copyWith(
          fontSize: 24,
          color: defaultTextStyle.style.color!.withOpacity(0.70),
          height: 1.15,
          fontWeight: FontWeight.normal,
        ),
        VerticalSpacing(top: 8, bottom: 0),
        VERTICAL_SPACING_EMPTY,
        VERTICAL_SPACING_EMPTY,
        null,
      ),
      h3: TextBlockStyleM(
        defaultTextStyle.style.copyWith(
          fontSize: 20,
          color: defaultTextStyle.style.color!.withOpacity(0.70),
          height: 1.25,
          fontWeight: FontWeight.w500,
        ),
        VerticalSpacing(top: 8, bottom: 0),
        VERTICAL_SPACING_EMPTY,
        VERTICAL_SPACING_EMPTY,
        null,
      ),
      paragraph: TextBlockStyleM(
        baseStyle,
        VERTICAL_SPACING_EMPTY,
        VERTICAL_SPACING_EMPTY,
        VERTICAL_SPACING_EMPTY,
        null,
      ),
      bold: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
      italic: const TextStyle(
        fontStyle: FontStyle.italic,
      ),
      small: const TextStyle(
        fontSize: 12,
        color: Colors.black45,
      ),
      underline: const TextStyle(
        decoration: TextDecoration.underline,
      ),
      strikeThrough: const TextStyle(
        decoration: TextDecoration.lineThrough,
      ),
      inlineCode: InlineCodeStyle(
        backgroundColor: Colors.grey.shade100,
        radius: const Radius.circular(3),
        style: inlineCodeStyle,
        header1: inlineCodeStyle.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w300,
        ),
        header2: inlineCodeStyle.copyWith(
          fontSize: 22,
        ),
        header3: inlineCodeStyle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      link: TextStyle(
        color: themeData.colorScheme.secondary,
        decoration: TextDecoration.underline,
      ),
      placeHolder: TextBlockStyleM(
        defaultTextStyle.style.copyWith(
          fontSize: 20,
          height: 1.5,
          color: Colors.grey.withOpacity(0.6),
        ),
        VERTICAL_SPACING_EMPTY,
        VERTICAL_SPACING_EMPTY,
        VERTICAL_SPACING_EMPTY,
        null,
      ),
      lists: ListBlockStyle(
        baseStyle,
        VERTICAL_BASE_SPACING,
        VerticalSpacing(top: 0, bottom: 6),
        VERTICAL_SPACING_EMPTY,
        null,
        null,
      ),
      quote: TextBlockStyleM(
        TextStyle(
          color: baseStyle.color!.withOpacity(0.6),
        ),
        VERTICAL_BASE_SPACING,
        VerticalSpacing(top: 6, bottom: 2),
        VERTICAL_SPACING_EMPTY,
        BoxDecoration(
          border: Border(
            left: BorderSide(
              width: 4,
              color: Colors.grey.shade300,
            ),
          ),
        ),
      ),
      code: TextBlockStyleM(
        GoogleFonts.robotoMono(
          color: Colors.blue.shade900.withOpacity(0.9),
          fontSize: 13,
          height: 1.15,
        ),
        VERTICAL_BASE_SPACING,
        VERTICAL_SPACING_EMPTY,
        VERTICAL_SPACING_EMPTY,
        BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      indent: TextBlockStyleM(
        baseStyle,
        VERTICAL_BASE_SPACING,
        VerticalSpacing(top: 0, bottom: 6),
        VERTICAL_SPACING_EMPTY,
        null,
      ),
      align: TextBlockStyleM(
        baseStyle,
        VERTICAL_SPACING_EMPTY,
        VERTICAL_SPACING_EMPTY,
        VERTICAL_SPACING_EMPTY,
        null,
      ),
      leading: TextBlockStyleM(
        baseStyle,
        VERTICAL_SPACING_EMPTY,
        VERTICAL_SPACING_EMPTY,
        VERTICAL_SPACING_EMPTY,
        null,
      ),
      sizeSmall: const TextStyle(
        fontSize: 10,
      ),
      sizeLarge: const TextStyle(
        fontSize: 18,
      ),
      sizeHuge: const TextStyle(
        fontSize: 22,
      ),
    );
  }

  // === PLATFORM STYLES ===

  // This method needs access to the build context.
  // It also needs to be executed before the rest of the widgets are built.
  // Therefore we built a condition to execute it only once.
  PlatformDependentStylesM initAndCachePlatformStyles(BuildContext context) {
    final styles = _getPlatformStyles(context);
    state.platformStyles.styles = styles;

    return styles;
  }

  CursorController initAndCacheCursorController() {
    final readOnly = !state.config.readOnly;

    // Cache the previous instance of the CursorController.
    if (state.refs.cursorControllerInitialised) {
      state.refs.oldCursorController = state.refs.cursorController;
    }

    state.refs.cursorController = CursorController(
      show: ValueNotifier<bool>(readOnly),
      style: cursorStyle(),
      tickerProvider: state.refs.widget,
      state: state,
    );

    return state.refs.cursorController;
  }

  // === CURSOR STYLES ===

  CursorStyle cursorStyle() {
    final defaultStyle = state.platformStyles.styles.cursorStyle;
    final paintCursorAboveText = state.config.paintCursorAboveText;

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
}
