import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_widget.dart';

import '../../controller/services/editor-controller.dart';
import '../../selection/models/gesture-detector-builder-delegate.model.dart';
import '../../selection/services/text-selection.service.dart';
import '../../selection/widgets/text-selection-gestures.dart';
import '../../shared/utils/platform.utils.dart';
import '../models/editor-cfg.model.dart';
import '../models/editor-state.model.dart';
import '../models/platform-dependent-styles-config.model.dart';
import '../services/styles.utils.dart';
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
// The Editor uses Flutter TextField to render the paragraphs in a column of content.
// On top of the regular TextField we are rendering custom selection controls or highlights using the RenderBox API.
//
// Gestures
// The VisualEditor class implements TextSelectionGesturesBuilderDelegate.
// This base class is used to separate the features related to gesture detection and gives the opportunity to override them.
class VisualEditor extends StatefulWidget {
  // Controller object which establishes a link between a rich text document and this editor.
  final EditorController controller;

  // Controls whether this editor has keyboard focus.
  final FocusNode focusNode;

  // Take control over the scroll of the Visual Editor when rendering in scrollable mode.
  final ScrollController scrollController;

  final EditorCfgM config;

  // Customize any of the settings available in VisualEditor
  const VisualEditor({
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.config,
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
        focusNode: FocusNode(),
        config: EditorCfgM(
          scrollable: true,
          autoFocus: true,
          readOnly: readOnly,
          padding: EdgeInsets.zero,
          keyboardAppearance: keyboardAppearance ?? Brightness.light,
        ),
      );

  @override
  VisualEditorState createState() => VisualEditorState();
}

class VisualEditorState extends State<VisualEditor>
    implements TextSelectionGesturesBuilderDelegateM {
  final _textSelectionService = TextSelectionService();

  final _stylesUtils = StylesUtils();
  final GlobalKey<EditorState> _editorKey = GlobalKey<EditorState>();

  @override
  void initState() {
    super.initState();
    _setupTextSelectionServiceState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectionTheme = TextSelectionTheme.of(context);
    final isAppleOs = isAppleOS(theme.platform);
    final platformStyles = isAppleOs
        ? _stylesUtils.getAppleOsStyles(selectionTheme, context)
        : _stylesUtils.getOtherOsStyles(selectionTheme, theme);

    final editor = _i18n(
      child: _textSelectionGestures(
        child: _editor(
          theme: theme,
          platformStyles: platformStyles,
        ),
      ),
    );

    if (kIsWeb) {
      return _preventKeyPropagationToParent(
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
  bool get selectionEnabled => widget.config.enableInteractiveSelection;

  void requestKeyboard() {
    _editorKey.currentState!.requestKeyboard();
  }

  Widget _i18n({required Widget child}) => I18n(
        initialLocale: widget.config.locale,
        child: child,
      );

  Widget _textSelectionGestures({required Widget child}) =>
      TextSelectionGestures(
        behavior: HitTestBehavior.translucent,
        child: child,
      );

  Widget _editor({
    required ThemeData theme,
    required PlatformDependentStylesCfgM platformStyles,
  }) =>
      RawEditor(
        key: _editorKey,
        controller: widget.controller,
        focusNode: widget.focusNode,
        scrollController: widget.scrollController,
        scrollable: widget.config.scrollable,
        scrollBottomInset: widget.config.scrollBottomInset,
        padding: widget.config.padding,
        readOnly: widget.config.readOnly,
        placeholder: widget.config.placeholder,
        onLaunchUrl: widget.config.onLaunchUrl,
        toolbarOptions: _toolbarOptions(),
        showSelectionHandles: isMobile(theme.platform),
        showCursor: widget.config.showCursor,
        cursorStyle: _stylesUtils.cursorStyle(
          platformStyles.cursorStyle,
          widget.config,
        ),
        textCapitalization: widget.config.textCapitalization,
        minHeight: widget.config.minHeight,
        maxHeight: widget.config.maxHeight,
        maxContentWidth: widget.config.maxContentWidth,
        customStyles: widget.config.customStyles,
        expands: widget.config.expands,
        autoFocus: widget.config.autoFocus,
        selectionColor: platformStyles.selectionColor,
        selectionCtrls: widget.config.textSelectionControls ??
            platformStyles.textSelectionControls,
        keyboardAppearance: widget.config.keyboardAppearance,
        enableInteractiveSelection: widget.config.enableInteractiveSelection,
        scrollPhysics: widget.config.scrollPhysics,
        embedBuilder: widget.config.embedBuilder,
        linkActionPickerDelegate: widget.config.linkActionPickerDelegate,
        customStyleBuilder: widget.config.customStyleBuilder,
        floatingCursorDisabled: widget.config.floatingCursorDisabled,
      );

  // Intercept RawKeyEvent on Web to prevent it from propagating to parents that
  // might interfere with the editor key behavior, such as SingleChildScrollView.
  // SingleChildScrollView reacts to keys.
  Widget _preventKeyPropagationToParent({required Widget child}) =>
      RawKeyboardListener(
        focusNode: FocusNode(
          onKey: (node, event) => KeyEventResult.skipRemainingHandlers,
        ),
        child: child,
        onKey: (_) {},
      );

  ToolbarOptions _toolbarOptions() => ToolbarOptions(
        copy: widget.config.enableInteractiveSelection,
        cut: widget.config.enableInteractiveSelection,
        paste: widget.config.enableInteractiveSelection,
        selectAll: widget.config.enableInteractiveSelection,
      );

  void _setupTextSelectionServiceState() {
    _textSelectionService.initState(
      state: this,
      controller: widget.controller,
    );
  }
}
