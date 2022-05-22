import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_widget.dart';

import '../../blocks/models/custom-builders.type.dart';
import '../../blocks/models/link-action.picker.type.dart';
import '../../blocks/services/default-link-action-picker-delegate.dart';
import '../../blocks/services/default-styles.utils.dart';
import '../../controller/services/editor-controller.dart';
import '../../cursor/models/cursor-style.model.dart';
import '../../embeds/widgets/default-embed-builder.dart';
import '../../inputs/models/gesture-detector-builder-delegate.dart';
import '../../inputs/services/text-selection-gesture-detector-builder-delegate.dart';
import '../../shared/utils/platform.utils.dart';
import '../models/editor-state.model.dart';
import '../services/editor-text-selection-detector.util.dart';
import 'raw-editor.dart';

// This is the main class of the Visual Editor.
// There are 2 constructors available, one for controlling all the settings of the editor in precise detail.
// The other one is the basic init that will spare you the pain of having to comb trough all the props.
// The default settings are carefully chosen to satisfy the basic needs of any app that needs rich text editing.
// The editor can be rendered either in scrollable mode or in expanded mode.
// Most apps will prefer the scrollable mode and a sticky EditorToolbar on top or at the bottom of the viewport.
// Use the expanded version when you want to stack multiple editors on top of each other.
// A placeholder text can be defined to be displayed when the editor has no contents.
// All the styles of the editor can be overridden using custom styles.
//
// Custom embeds
// Besides the existing styled text options the editor can also render custom embeds such as video players or whatever
// else the client apps desire to render in the documents.
// Any kind of widget can be provided to be displayed in the middle of the document text.
//
// Callbacks
// Several callbacks are available to be used when interacting with the editor:
// - onTapDown()
// - onTapUp()
// - onSingleLongTapStart()
// - onSingleLongTapMoveUpdate()
// - onSingleLongTapEnd()
//
// Controller
// Each instance of the editor will need an EditorController.
// EditorToolbar can be synced to VisualEditor via the EditorController.
//
// Rendering
// The Editor uses Flutter TextField to render the paragraphs in a collumn of content.
// On top of the regular TextField we are rendering custom selection controls or highlights using the RenderBox API.
//
// Gestures
// The VisualEditor class implements EditorTextSelectionGestureDetectorBuilderDelegate.
// This base class is used to separate the features related to gesture detection and to give the opportunity to override them.
class VisualEditor extends StatefulWidget {
  // Controller object which establishes a link between a rich text document and this editor.
  final EditorController controller;

  // Controls whether this editor has keyboard focus. +++ REVIEW
  final FocusNode focusNode;

  // Take control over the scroll of the Visual Editor when rendering in scrollable mode.
  final ScrollController scrollController;

  // Whether the editor should create a scrollable container for its blocks.
  // When set to `true` the editor's height can be controlled by minHeight, maxHeight and expands properties.
  // When set to `false` the editor always expands to fit the entire blocks of the document and
  // should be placed as a child of another scrollable widget, otherwise the blocks may be clipped.
  final bool scrollable;

  // TODO DOC (currently not sure why this is defined)
  final double scrollBottomInset;

  // Additional space around the blocks of this editor.
  final EdgeInsetsGeometry padding;

  // Whether this editor should focus itself if nothing else is already focused.
  // If true, the keyboard will open as soon as this editor obtains focus.
  // Otherwise, the keyboard is only shown after the user taps the editor.
  final bool autoFocus;

  // The cursor refers to the blinking caret when the editor is focused.
  final bool? showCursor;

  // TODO DOC (currently not sure why this is defined)
  final bool? paintCursorAboveText;

  // When this is set to `true`, the text cannot be modified by any shortcut or keyboard operation.
  // The text remains selectable.
  final bool readOnly;

  // Content to be displayed when there is no content in the Delta document
  final String? placeholder;

  // Whether to enable user interface for changing the text selection.
  // For example, setting this to true will enable features such as long-pressing the editor to select text
  // and show the cut/copy/paste menu, and tapping to move the text cursor.
  // When this is false, the text selection cannot be adjusted by the user,
  // text cannot be copied, and the user cannot paste into the text field from the clipboard.
  final bool enableInteractiveSelection;

  // The minimum height to be occupied by this editor.
  // This only has effect if scrollable is set to `true` and expands is set to `false`.
  final double? minHeight;

  // The maximum height to be occupied by this editor.
  // This only has effect if scrollable is set to `true` and expands is set to `false`.
  final double? maxHeight;

  // The contents will be constrained by the maximum width and horizontally centered.
  // The scrollbar remains on the right side of the screen.
  // This is mostly useful on devices with wide screens.
  final double? maxContentWidth;

  final DefaultStyles? customStyles;

  // +++ Consider converting to enum
  // Whether this editor's height will be sized to fill its parent.
  // This only has effect if scrollable is set to `true`.
  // If expands is set to true and wrapped in a parent widget like Expanded or SizedBox, the editor will expand to fill the parent.
  // maxHeight and minHeight must both be `null` when this is set to `true`.
  final bool expands;

  // Configures how the platform keyboard will select an uppercase or lowercase keyboard.
  // Only supports text keyboards, other keyboard types will ignore this configuration.
  // Capitalization is locale-aware.
  // Defaults to TextCapitalization.sentences. Must not be `null`.
  final TextCapitalization textCapitalization;

  // The appearance of the keyboard.
  // This setting is only honored on iOS devices.
  final Brightness keyboardAppearance;

  // The ScrollPhysics to use when vertically scrolling the input.
  // This only has effect if scrollable is set to `true`.
  // If not specified, it will behave according to the current platform.
  // See Scrollable.physics.
  final ScrollPhysics? scrollPhysics;

  // Callback to invoke when user wants to launch a URL.
  final ValueChanged<String>? onLaunchUrl;

  // Returns whether gesture is handled
  final bool Function(
    TapDownDetails details,
    TextPosition Function(Offset offset),
  )? onTapDown;

  // Returns whether gesture is handled
  final bool Function(
    TapUpDetails details,
    TextPosition Function(Offset offset),
  )? onTapUp;

  // Returns whether gesture is handled
  final bool Function(
    LongPressStartDetails details,
    TextPosition Function(Offset offset),
  )? onSingleLongTapStart;

  // Returns whether gesture is handled
  final bool Function(
    LongPressMoveUpdateDetails details,
    TextPosition Function(Offset offset),
  )? onSingleLongTapMoveUpdate;

  // Returns whether gesture is handled
  final bool Function(
    LongPressEndDetails details,
    TextPosition Function(Offset offset),
  )? onSingleLongTapEnd;

  // Renders custom content to be displayed as provided by the client apps.
  // Custom embeds don't work as editable text, they are standalone blocks of content that have their own internal behaviour.
  final EmbedBuilder embedBuilder;

  // Styles can be provided to customize the look and feel of the Visual Editor.
  final CustomStyleBuilder? customStyleBuilder;

  // The locale to use for the editor buttons, defaults to system locale.
  final Locale? locale;

  // Delegate function responsible for showing menu with link actions on mobile platforms (iOS, Android).
  // The menu is triggered in editing mode when the user long-presses a link-styled text segment.
  // VisualEditor provides default implementation which can be overridden by this field to customize the user experience.
  // By default on iOS the menu is displayed with showCupertinoModalPopup which constructs an instance of CupertinoActionSheet.
  // For Android, the menu is displayed with showModalBottomSheet and a list of Material ListTiles.
  final LinkActionPickerDelegate linkActionPickerDelegate;

  // A floating cursor will help you to see what is currently under your thumb when moving the caret.
  final bool floatingCursorDisabled;

  // Custom GUI for text selection controls
  final TextSelectionControls? textSelectionControls;

  // Customize any of the settings available in VisualEditor
  const VisualEditor({
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.scrollable,
    required this.padding,
    this.autoFocus = false,
    this.readOnly = false,
    this.expands = false,
    this.showCursor,
    this.paintCursorAboveText,
    this.placeholder,
    this.enableInteractiveSelection = true,
    this.scrollBottomInset = 0,
    this.minHeight,
    this.maxHeight,
    this.maxContentWidth,
    this.customStyles,
    this.textCapitalization = TextCapitalization.sentences,
    this.keyboardAppearance = Brightness.light,
    this.scrollPhysics,
    this.onLaunchUrl,
    this.onTapDown,
    this.onTapUp,
    this.onSingleLongTapStart,
    this.onSingleLongTapMoveUpdate,
    this.onSingleLongTapEnd,
    this.embedBuilder = defaultEmbedBuilder,
    this.linkActionPickerDelegate = defaultLinkActionPickerDelegate,
    this.customStyleBuilder,
    this.locale,
    this.floatingCursorDisabled = false,
    this.textSelectionControls,
    Key? key,
  }) : super(key: key);

  // Quickly a basic Visual Editor using a basic configuration
  factory VisualEditor.basic({
    required EditorController controller,
    required bool readOnly,
    Brightness? keyboardAppearance,
  }) =>
      VisualEditor(
        controller: controller,
        scrollController: ScrollController(),
        scrollable: true,
        focusNode: FocusNode(),
        autoFocus: true,
        readOnly: readOnly,
        padding: EdgeInsets.zero,
        keyboardAppearance: keyboardAppearance ?? Brightness.light,
      );

  @override
  VisualEditorState createState() => VisualEditorState();
}

class VisualEditorState extends State<VisualEditor>
    implements EditorTextSelectionGestureDetectorBuilderDelegate {
  final GlobalKey<EditorState> _editorKey = GlobalKey<EditorState>();
  late EditorTextSelectionGestureDetectorBuilder
      _selectionGestureDetectorBuilder;

  @override
  void initState() {
    super.initState();
    _buildTextSelectionGestureDetector();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectionTheme = TextSelectionTheme.of(context);

    TextSelectionControls textSelectionControls;
    bool paintCursorAboveText;
    bool cursorOpacityAnimates;
    Offset? cursorOffset;
    Color? cursorColor;
    Color selectionColor;
    Radius? cursorRadius;

    if (isAppleOS(theme.platform)) {
      final cupertinoTheme = CupertinoTheme.of(context);
      textSelectionControls = cupertinoTextSelectionControls;
      paintCursorAboveText = true;
      cursorOpacityAnimates = true;
      cursorColor ??= selectionTheme.cursorColor ?? cupertinoTheme.primaryColor;
      selectionColor = selectionTheme.selectionColor ??
          cupertinoTheme.primaryColor.withOpacity(0.40);
      cursorRadius ??= const Radius.circular(2);
      cursorOffset = Offset(
        iOSHorizontalOffset / MediaQuery.of(context).devicePixelRatio,
        0,
      );
    } else {
      textSelectionControls = materialTextSelectionControls;
      paintCursorAboveText = false;
      cursorOpacityAnimates = false;
      cursorColor ??= selectionTheme.cursorColor ?? theme.colorScheme.primary;
      selectionColor = selectionTheme.selectionColor ??
          theme.colorScheme.primary.withOpacity(0.40);
    }

    final child = RawEditor(
      key: _editorKey,
      controller: widget.controller,
      focusNode: widget.focusNode,
      scrollController: widget.scrollController,
      scrollable: widget.scrollable,
      scrollBottomInset: widget.scrollBottomInset,
      padding: widget.padding,
      readOnly: widget.readOnly,
      placeholder: widget.placeholder,
      onLaunchUrl: widget.onLaunchUrl,
      toolbarOptions: ToolbarOptions(
        copy: widget.enableInteractiveSelection,
        cut: widget.enableInteractiveSelection,
        paste: widget.enableInteractiveSelection,
        selectAll: widget.enableInteractiveSelection,
      ),
      showSelectionHandles: isMobile(theme.platform),
      showCursor: widget.showCursor,
      cursorStyle: CursorStyle(
        color: cursorColor,
        backgroundColor: Colors.grey,
        width: 2,
        radius: cursorRadius,
        offset: cursorOffset,
        paintAboveText: widget.paintCursorAboveText ?? paintCursorAboveText,
        opacityAnimates: cursorOpacityAnimates,
      ),
      textCapitalization: widget.textCapitalization,
      minHeight: widget.minHeight,
      maxHeight: widget.maxHeight,
      maxContentWidth: widget.maxContentWidth,
      customStyles: widget.customStyles,
      expands: widget.expands,
      autoFocus: widget.autoFocus,
      selectionColor: selectionColor,
      selectionCtrls: widget.textSelectionControls ?? textSelectionControls,
      keyboardAppearance: widget.keyboardAppearance,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      scrollPhysics: widget.scrollPhysics,
      embedBuilder: widget.embedBuilder,
      linkActionPickerDelegate: widget.linkActionPickerDelegate,
      customStyleBuilder: widget.customStyleBuilder,
      floatingCursorDisabled: widget.floatingCursorDisabled,
    );

    final editor = I18n(
        initialLocale: widget.locale,
        child: _selectionGestureDetectorBuilder.build(
          behavior: HitTestBehavior.translucent,
          child: child,
        ));

    if (kIsWeb) {
      // Intercept RawKeyEvent on Web to prevent it from propagating to parents
      // that might interfere with the editor key behavior, such as
      // SingleChildScrollView. Thanks to @wliumelb for the workaround.
      // See issue https://github.com/singerdmx/flutter-quill/issues/304
      return RawKeyboardListener(
        onKey: (_) {},
        focusNode: FocusNode(
          onKey: (node, event) => KeyEventResult.skipRemainingHandlers,
        ),
        child: editor,
      );
    }

    return editor;
  }

  @override
  GlobalKey<EditorState> get editableTextKey => _editorKey;

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => widget.enableInteractiveSelection;

  void requestKeyboard() {
    _editorKey.currentState!.requestKeyboard();
  }

  void _buildTextSelectionGestureDetector() {
    _selectionGestureDetectorBuilder =
        EditorSelectionGestureDetectorBuilder(this, widget.controller);
  }
}
