import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import '../../blocks/models/custom-builders.type.dart';
import '../../blocks/models/link-action-menu.enum.dart';
import '../../blocks/models/link-action.picker.type.dart';
import '../../blocks/services/default-link-action-picker-delegate.dart';
import '../../blocks/services/default-styles.utils.dart';
import '../../blocks/services/editor-styles.utils.dart';
import '../../blocks/widgets/editable-text-line.dart';
import '../../blocks/widgets/text-block.dart';
import '../../blocks/widgets/text-line.dart';
import '../../controller/services/editor-controller.dart';
import '../../controller/services/editor-text.service.dart';
import '../../controller/state/scroll-controller.state.dart';
import '../../cursor/models/cursor-style.model.dart';
import '../../cursor/services/cursor.controller.dart';
import '../../cursor/services/cursor.service.dart';
import '../../cursor/state/cursor-controller.state.dart';
import '../../delta/services/delta.utils.dart';
import '../../documents/models/attribute.dart';
import '../../documents/models/document.dart';
import '../../documents/models/nodes/block.dart';
import '../../documents/models/nodes/line.dart';
import '../../documents/models/nodes/node.dart';
import '../../embeds/widgets/default-embed-builder.dart';
import '../../inputs/services/keyboard.service.dart';
import '../../inputs/state/keyboard-visible.state.dart';
import '../../inputs/widgets/editor-keyboard-listener.dart';
import '../../selection/services/selection-actions.service.dart';
import '../../selection/services/text-selection.service.dart';
import '../../shared/utils/platform.utils.dart';
import '../services/clipboard.service.dart';
import '../services/input-connection.service.dart';
import '../services/keyboard-actions.service.dart';
import '../services/raw-editor.utils.dart';
import '../services/styles.utils.dart';
import '../services/text-block.utils.dart';
import '../state/editor-config.state.dart';
import '../state/focus-node.state.dart';
import '../state/raw-editor-swidget.state.dart';
import '../state/raw-editor-widget.state.dart';
import 'proxy/baseline-proxy.dart';
import 'raw-editor-renderer.dart';
import 'scroll/editor-single-child-scroll-view.dart';

class RawEditor extends StatefulWidget {
  final _rawEditorWidgetState = RawEditorWidgetState();

  RawEditor({
    required this.controller,
    required this.scrollController,
    required this.scrollBottomInset,
    required this.editorRendererKey,
    Key? key,
    this.scrollable = true,
    this.padding = EdgeInsets.zero,
    this.readOnly = false,
    this.placeholder,
    this.onLaunchUrl,
    this.textCapitalization = TextCapitalization.none,
    this.maxHeight,
    this.minHeight,
    this.maxContentWidth,
    this.customStyles,
    this.expands = false,
    this.autoFocus = false,
    this.keyboardAppearance = Brightness.light,
    this.enableInteractiveSelection = true,
    this.scrollPhysics,
    this.embedBuilder = defaultEmbedBuilder,
    this.linkActionPickerDelegate = defaultLinkActionPickerDelegate,
    this.customStyleBuilder,
    this.floatingCursorDisabled = false,
  })  : assert(maxHeight == null || maxHeight > 0, 'maxHeight cannot be null'),
        assert(minHeight == null || minHeight >= 0, 'minHeight cannot be null'),
        assert(maxHeight == null || minHeight == null || maxHeight >= minHeight,
            'maxHeight cannot be null'),
        super(key: key) {
    _rawEditorWidgetState.setRawEditor(this);
  }

  // Controls the document being edited.
  final GlobalKey editorRendererKey;

  // Controls the document being edited.
  final EditorController controller;

  // Controls whether this editor has keyboard focus.
  final ScrollController scrollController;
  final bool scrollable;
  final double scrollBottomInset;

  // Additional space around the editor contents.
  final EdgeInsetsGeometry padding;

  // Whether the text can be changed.
  // When this is set to true, the text cannot be modified by any shortcut or keyboard operation. The text is still selectable.
  final bool readOnly;

  final String? placeholder;

  // Callback which is triggered when the user wants to open a URL from a link in the document.
  final ValueChanged<String>? onLaunchUrl;

  // Configures how the platform keyboard will select an uppercase or lowercase keyboard.
  // Only supports text keyboards, other keyboard types will ignore this configuration.
  // Capitalization is locale-aware.
  // Defaults to TextCapitalization.none. Must not be null.
  final TextCapitalization textCapitalization;

  // The maximum height this editor can have.
  // If this is null then there is no limit to the editor's height and it will expand to fill its parent.
  final double? maxHeight;

  // The minimum height this editor can have.
  final double? minHeight;

  // The maximum width to be occupied by the blocks of this editor.
  // If this is not null and and this editor's width is larger than this value then the contents
  // will be constrained to the provided maximum width and horizontally centered.
  // This is mostly useful on devices with wide screens.
  final double? maxContentWidth;

  final DefaultStyles? customStyles;

  // Whether this widget's height will be sized to fill its parent.
  // If set to true and wrapped in a parent widget like Expanded or defaults to false.
  final bool expands;

  // Whether this editor should focus itself if nothing else is already focused.
  // If true, the keyboard will open as soon as this text field obtains focus.
  // Otherwise, the keyboard is only shown after the user taps the text field.
  // Defaults to false. Cannot be null.
  final bool autoFocus;

  // The appearance of the keyboard.
  // This setting is only honored on iOS devices.
  // Defaults to Brightness.light.
  final Brightness keyboardAppearance;

  // If true, then long-pressing this TextField will select text and show the
  // cut/copy/paste menu, and tapping will move the text caret.
  // True by default.
  // If false, most of the accessibility support for selecting text, copy and paste, and moving the caret will be disabled.
  final bool enableInteractiveSelection;

  // The ScrollPhysics to use when vertically scrolling the input.
  // If not specified, it will behave according to the current platform.
  final ScrollPhysics? scrollPhysics;

  // Builder function for embeddable objects.
  final EmbedBuilder embedBuilder;
  final LinkActionPickerDelegate linkActionPickerDelegate;
  final CustomStyleBuilder? customStyleBuilder;
  final bool floatingCursorDisabled;

  @override
  State<StatefulWidget> createState() => RawEditorState();
}

class RawEditorState extends State<RawEditor>
    with
        AutomaticKeepAliveClientMixin<RawEditor>,
        WidgetsBindingObserver,
        TickerProviderStateMixin<RawEditor>
    implements TextSelectionDelegate, TextInputClient {
  final _selectionActionsService = SelectionActionsService();
  final _textSelectionService = TextSelectionService();
  final _editorTextService = EditorTextService();
  final _cursorService = CursorService();
  final _clipboardService = ClipboardService();
  final _textConnectionService = TextConnectionService();
  final _scrollControllerState = ScrollControllerState();
  final _keyboardService = KeyboardService();
  final _keyboardActionsService = KeyboardActionsService();
  final _rawEditorUtils = RawEditorUtils();
  final _rawEditorSWidgetState = RawEditorSWidgetState();
  final _editorConfigState = EditorConfigState();
  final _focusNodeState = FocusNodeState();
  final _stylesUtils = StylesUtils();
  final _textBlockUtils = TextBlockUtils();
  final _keyboardVisibleState = KeyboardVisibleState();
  final _cursorControllerState = CursorControllerState();

  late CursorStyle _cursorStyle;
  KeyboardVisibilityController? _keyboardVisibilityController;
  StreamSubscription<bool>? _keyboardVisibilitySubscription;
  bool _didAutoFocus = false;
  DefaultStyles? _styles;
  final ClipboardStatusNotifier clipboardStatus = ClipboardStatusNotifier();
  final LayerLink toolbarLayerLink = LayerLink();
  final LayerLink startHandleLayerLink = LayerLink();
  final LayerLink endHandleLayerLink = LayerLink();

  // Controls the floating cursor animation when it is released.
  // The floating cursor is animated to merge with the regular cursor.
  late AnimationController _floatingCursorResetController;
  TextDirection get _textDirection => Directionality.of(context);

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    super.build(context);

    var _doc = widget.controller.document;

    if (_doc.isEmpty() && widget.placeholder != null) {
      _doc = Document.fromJson(
        jsonDecode(
          '[{"attributes":{"placeholder":true},"insert":"${widget.placeholder}\\n"}]',
        ),
      );
    }

    Widget wrappedEditor = CompositedTransformTarget(
      link: toolbarLayerLink,
      child: Semantics(
        child: RawEditorRenderer(
          key: widget.editorRendererKey,
          document: _doc,
          selection: widget.controller.selection,
          scrollable: widget.scrollable,
          cursorController: _cursorControllerState.controller,
          textDirection: _textDirection,
          startHandleLayerLink: startHandleLayerLink,
          endHandleLayerLink: endHandleLayerLink,
          onSelectionChanged: _rawEditorUtils.handleSelectionChanged,
          onSelectionCompleted: _handleSelectionCompleted,
          scrollBottomInset: widget.scrollBottomInset,
          padding: widget.padding,
          maxContentWidth: widget.maxContentWidth,
          floatingCursorDisabled: widget.floatingCursorDisabled,
          children: _buildChildren(_doc, context),
        ),
      ),
    );

    if (widget.scrollable) {
      // Since [SingleChildScrollView] does not implement `computeDistanceToActualBaseline` it prevents
      // the editor from  providing its baseline metrics.
      // To address this issue we wrap the scroll view with [BaselineProxy] which mimics the editor's baseline.
      // This implies that the first line has no styles applied to it.
      final baselinePadding = EdgeInsets.only(
        top: _styles!.paragraph!.verticalSpacing.item1,
      );
      wrappedEditor = BaselineProxy(
        textStyle: _styles!.paragraph!.style,
        padding: baselinePadding,
        child: EditorSingleChildScrollView(
          physics: widget.scrollPhysics,
          viewportBuilder: (_, offset) => CompositedTransformTarget(
            link: toolbarLayerLink,
            child: RawEditorRenderer(
              key: widget.editorRendererKey,
              offset: offset,
              document: _doc,
              selection: widget.controller.selection,
              scrollable: widget.scrollable,
              textDirection: _textDirection,
              startHandleLayerLink: startHandleLayerLink,
              endHandleLayerLink: endHandleLayerLink,
              onSelectionChanged: _rawEditorUtils.handleSelectionChanged,
              onSelectionCompleted: _handleSelectionCompleted,
              scrollBottomInset: widget.scrollBottomInset,
              padding: widget.padding,
              maxContentWidth: widget.maxContentWidth,
              cursorController: _cursorControllerState.controller,
              floatingCursorDisabled: widget.floatingCursorDisabled,
              children: _buildChildren(_doc, context),
            ),
          ),
        ),
      );
    }

    final constraints = widget.expands
        ? const BoxConstraints.expand()
        : BoxConstraints(
            minHeight: widget.minHeight ?? 0.0,
            maxHeight: widget.maxHeight ?? double.infinity,
          );

    return EditorStylesUtils(
      data: _styles!,
      child: Actions(
        actions: _getActionsSafe(context),
        child: Focus(
          focusNode: _focusNodeState.node,
          child: EditorKeyboardListener(
            child: Container(
              constraints: constraints,
              child: wrappedEditor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _rawEditorSWidgetState.setRawEditorState(this);

    _cursorStyle = _stylesUtils.cursorStyle();
    clipboardStatus.addListener(_onChangedClipboardStatus);

    widget.controller.addListener(() {
      _rawEditorUtils.didChangeTextEditingValue(
        widget.controller.ignoreFocusOnTextChange,
      );
    });
    _scrollControllerState.controller.addListener(
      _updateSelectionOverlayForScroll,
    );

    _cursorControllerState.setController(
      CursorController(
        show: ValueNotifier<bool>(_editorConfigState.config.showCursor),
        style: _cursorStyle,
        tickerProvider: this,
      ),
    );

    // Floating cursor
    _floatingCursorResetController = AnimationController(vsync: this);
    _floatingCursorResetController.addListener(
      () => _textConnectionService.onFloatingCursorResetTick(
        _floatingCursorResetController,
      ),
    );

    // +++ Migrate
    if (isKeyboardOS()) {
      _keyboardVisibleState.setKeyboardVisible(true);
    } else {
      // Treat iOS Simulator like a keyboard OS
      isIOSSimulator().then((isIosSimulator) {
        if (isIosSimulator) {
          _keyboardVisibleState.setKeyboardVisible(true);
        } else {
          _keyboardVisibilityController = KeyboardVisibilityController();
          _keyboardVisibleState.setKeyboardVisible(
            _keyboardVisibilityController!.isVisible,
          );
          _keyboardVisibilitySubscription =
              _keyboardVisibilityController?.onChange.listen((visible) {
            _keyboardVisibleState.setKeyboardVisible(visible);

            if (visible) {
              _rawEditorUtils.onChangeTextEditingValue(
                !_focusNodeState.node.hasFocus,
              );
            }
          });

          HardwareKeyboard.instance.addHandler(hardwareKeyboardEvent);
        }
      });
    }

    // Focus
    _focusNodeState.node.addListener(
      _rawEditorUtils.handleFocusChanged,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentStyles = EditorStylesUtils.getStyles(context, true);
    final defaultStyles = DefaultStyles.getInstance(context);
    _styles = (parentStyles != null)
        ? defaultStyles.merge(parentStyles)
        : defaultStyles;

    if (widget.customStyles != null) {
      _styles = _styles!.merge(widget.customStyles!);
    }

    if (!_didAutoFocus && widget.autoFocus) {
      FocusScope.of(context).autofocus(_focusNodeState.node);
      _didAutoFocus = true;
    }
  }

  @override
  void didUpdateWidget(RawEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    _cursorControllerState.controller.show.value = _editorConfigState.config.showCursor;
    _cursorControllerState.controller.style = _cursorStyle;

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(
        _rawEditorUtils.didChangeTextEditingValue,
      );
      widget.controller.addListener(
        _rawEditorUtils.didChangeTextEditingValue,
      );
      _textConnectionService.updateRemoteValueIfNeeded();
    }

    // +++ REVIEW in Quill, not sure why this exists
    // if (widget.scrollController != _scrollControllerState.controller) {
    //   _scrollControllerState.controller.removeListener(_updateSelectionOverlayForScroll);
    //   _scrollController = widget.scrollController;
    //   _scrollControllerState.controller.addListener(_updateSelectionOverlayForScroll);
    // }

    // +++ Might be outdated since we no longer keep the focus node in the scope of the widget state
    // if (widget.focusNode != oldWidget.focusNode) {
    //   oldWidget.focusNode.removeListener(_handleFocusChanged);
    //   widget.focusNode.addListener(_handleFocusChanged);
    //   updateKeepAlive();
    // }

    if (widget.controller.selection != oldWidget.controller.selection) {
      _selectionActionsService.selectionActions?.update(textEditingValue);
    }

    _selectionActionsService.selectionActions?.handlesVisible =
        _rawEditorUtils.shouldShowSelectionHandles();

    if (!_textConnectionService.shouldCreateInputConnection) {
      _textConnectionService.closeConnectionIfNeeded();
    } else {
      if (oldWidget.readOnly && _focusNodeState.node.hasFocus) {
        _textConnectionService.openConnectionIfNeeded();
      }
    }

    // in case customStyles changed in new widget
    if (widget.customStyles != null) {
      _styles = _styles!.merge(widget.customStyles!);
    }
  }

  @override
  void dispose() {
    _textConnectionService.closeConnectionIfNeeded();
    _keyboardVisibilitySubscription?.cancel();
    HardwareKeyboard.instance.removeHandler(hardwareKeyboardEvent);

    assert(!_textConnectionService.hasConnection);

    _selectionActionsService.selectionActions?.dispose();
    _selectionActionsService.selectionActions = null;
    widget.controller.removeListener(_rawEditorUtils.didChangeTextEditingValue);
    _focusNodeState.node.removeListener(_rawEditorUtils.handleFocusChanged);
    _cursorControllerState.controller.dispose();
    clipboardStatus
      ..removeListener(_onChangedClipboardStatus)
      ..dispose();

    super.dispose();
  }

  // === CLIPBOARD OVERRIDES ===

  @override
  void copySelection(SelectionChangedCause cause) {
    _clipboardService.copySelection(
      cause,
      widget.controller,
    );
  }

  @override
  void cutSelection(SelectionChangedCause cause) {
    _clipboardService.cutSelection(
      cause,
      widget.controller,
    );
  }

  @override
  Future<void> pasteText(SelectionChangedCause cause) async =>
      _clipboardService.pasteText(
        cause,
        widget.controller,
      );

  @override
  void selectAll(SelectionChangedCause cause) {
    _textSelectionService.selectAll(cause);
  }

  // === INPUT CLIENT OVERRIDES ===

  @override
  bool get wantKeepAlive => _focusNodeState.node.hasFocus;

  // Not implemented
  @override
  void insertTextPlaceholder(Size size) {}

  // Not implemented
  @override
  void removeTextPlaceholder() {}

  // No-op
  @override
  void performAction(TextInputAction action) {}

  // No-op
  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  // Autofill is not needed
  @override
  AutofillScope? get currentAutofillScope => null;

  // Not implemented
  @override
  void showAutocorrectionPromptRect(int start, int end) =>
      throw UnimplementedError();

  @override
  TextEditingValue? get currentTextEditingValue =>
      _textConnectionService.currentTextEditingValue;

  @override
  void updateEditingValue(TextEditingValue value) {
    _textConnectionService.updateEditingValue(value, widget.controller);
  }

  @override
  void updateFloatingCursor(
    RawFloatingCursorPoint point,
  ) {
    _textConnectionService.updateFloatingCursor(
      point,
      _floatingCursorResetController,
    );
  }

  @override
  void connectionClosed() => _textConnectionService.connectionClosed();

  // === TEXT SELECTION OVERRIDES ===

  @override
  bool showToolbar() => _selectionActionsService.showToolbar();

  @override
  void hideToolbar([bool hideHandles = true]) {
    _selectionActionsService.hideToolbar(hideHandles);
  }

  @override
  TextEditingValue get textEditingValue => _editorTextService.textEditingValue;

  @override
  void userUpdateTextEditingValue(
    TextEditingValue value,
    SelectionChangedCause cause,
  ) {
    _editorTextService.userUpdateTextEditingValue(value, cause);
  }

  @override
  void bringIntoView(TextPosition position) {
    _cursorService.bringIntoView(position);
  }

  @override
  bool get cutEnabled => _clipboardService.cutEnabled();

  @override
  bool get copyEnabled => _clipboardService.copyEnabled();

  @override
  bool get pasteEnabled => _clipboardService.pasteEnabled();

  @override
  bool get selectAllEnabled => _textSelectionService.selectAllEnabled();

  bool hardwareKeyboardEvent(KeyEvent _) =>
      _keyboardService.hardwareKeyboardEvent(this, _rawEditorUtils);

  // === PRIVATE ===

  List<Widget> _buildChildren(Document doc, BuildContext context) {
    final result = <Widget>[];
    final indentLevelCounts = <int, int>{};

    for (final node in doc.root.children) {
      if (node is Line) {
        final editableTextLine = _getEditableTextLineFromNode(node, context);
        result.add(
          Directionality(
            textDirection: getDirectionOfNode(node),
            child: editableTextLine,
          ),
        );
      } else if (node is Block) {
        final attrs = node.style.attributes;
        final editableTextBlock = EditableTextBlock(
          block: node,
          controller: widget.controller,
          textDirection: _textDirection,
          scrollBottomInset: widget.scrollBottomInset,
          verticalSpacing: _textBlockUtils.getVerticalSpacingForBlock(
            node,
            _styles,
          ),
          textSelection: widget.controller.selection,
          styles: _styles,
          enableInteractiveSelection: widget.enableInteractiveSelection,
          hasFocus: _focusNodeState.node.hasFocus,
          // +++ Replace at root level
          contentPadding: attrs.containsKey(Attribute.codeBlock.key)
              ? const EdgeInsets.all(16)
              : null,
          embedBuilder: widget.embedBuilder,
          linkActionPicker: _linkActionPicker,
          onLaunchUrl: widget.onLaunchUrl,
          cursorController: _cursorControllerState.controller,
          indentLevelCounts: indentLevelCounts,
          onCheckboxTap: _textBlockUtils.handleCheckboxTap,
          readOnly: widget.readOnly,
          customStyleBuilder: widget.customStyleBuilder,
        );

        result.add(
          Directionality(
            textDirection: getDirectionOfNode(node),
            child: editableTextBlock,
          ),
        );
      } else {
        throw StateError('Unreachable.');
      }
    }

    return result;
  }

  EditableTextLine _getEditableTextLineFromNode(
    Line node,
    BuildContext context,
  ) {
    final textLine = TextLine(
      line: node,
      textDirection: _textDirection,
      embedBuilder: widget.embedBuilder,
      customStyleBuilder: widget.customStyleBuilder,
      styles: _styles!,
      readOnly: widget.readOnly,
      controller: widget.controller,
      linkActionPicker: _linkActionPicker,
      onLaunchUrl: widget.onLaunchUrl,
    );
    final editableTextLine = EditableTextLine(
      controller: widget.controller,
      line: node,
      leading: null,
      body: textLine,
      indentWidth: 0,
      verticalSpacing: _textBlockUtils.getVerticalSpacingForLine(node, _styles),
      textDirection: _textDirection,
      textSelection: widget.controller.selection,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      hasFocus: _focusNodeState.node.hasFocus,
      devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
      cursorController: _cursorControllerState.controller,
    );

    return editableTextLine;
  }

  void refresh() => setState(() {});
  void safeUpdateKeepAlive() => updateKeepAlive();

  Map<Type, Action<Intent>> _getActionsSafe(BuildContext context) {
    return widget.editorRendererKey.currentContext != null
        ? _keyboardActionsService.getActions(context)
        : {};
  }

  void _handleSelectionCompleted() {
    widget.controller.onSelectionCompleted?.call();
  }

  void _updateSelectionOverlayForScroll() {
    _selectionActionsService.selectionActions?.updateForScroll();
  }

  void _onChangedClipboardStatus() {
    if (!mounted) {
      return;
    }

    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
      // Trigger build and updateChildren
    });
  }

  Future<LinkMenuAction> _linkActionPicker(Node linkNode) async {
    final link = linkNode.style.attributes[Attribute.link.key]!.value!;
    return widget.linkActionPickerDelegate(context, link, linkNode);
  }
}
