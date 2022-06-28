import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:i18n_extension/i18n_widget.dart';

import 'blocks/models/default-styles.model.dart';
import 'controller/services/editor-controller.dart';
import 'controller/services/editor-text.service.dart';
import 'controller/state/document.state.dart';
import 'controller/state/editor-controller.state.dart';
import 'controller/state/scroll-controller.state.dart';
import 'cursor/controllers/floating-cursor.controller.dart';
import 'cursor/services/cursor.service.dart';
import 'documents/models/document.model.dart';
import 'documents/services/document.service.dart';
import 'editor/models/editor-cfg.model.dart';
import 'editor/services/editor.service.dart';
import 'editor/services/styles.service.dart';
import 'editor/services/text-value.service.dart';
import 'editor/state/editor-config.state.dart';
import 'editor/state/editor-state-widget.state.dart';
import 'editor/state/editor-widget.state.dart';
import 'editor/state/editor.state.dart';
import 'editor/state/focus-node.state.dart';
import 'editor/widgets/document-styles.dart';
import 'editor/widgets/editor-renderer.dart';
import 'editor/widgets/proxy/baseline-proxy.dart';
import 'editor/widgets/scroll/editor-single-child-scroll-view.dart';
import 'inputs/services/clipboard.service.dart';
import 'inputs/services/input-connection.service.dart';
import 'inputs/services/keyboard-actions.service.dart';
import 'inputs/services/keyboard.service.dart';
import 'inputs/widgets/editor-keyboard-listener.dart';
import 'selection/controllers/selection-actions.controller.dart';
import 'selection/services/selection-actions.service.dart';
import 'selection/services/text-selection.service.dart';
import 'selection/state/selection-layers.state.dart';
import 'selection/widgets/text-gestures.dart';

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
// Besides the existing styled text options the editor can also render custom embeds such as video players
// or whatever else the client apps desire to render in the documents.
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
  final _editorWidgetState = EditorWidgetState();
  final _editorControllerState = EditorControllerState();
  final _scrollControllerState = ScrollControllerState();
  final _focusNodeState = FocusNodeState();
  final _editorConfigState = EditorConfigState();

  final EditorController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final EditorConfigM config;

  VisualEditor({
    required this.controller,
    required this.scrollController,
    required this.focusNode,
    required this.config,
    Key? key,
  }) : super(key: key) {
    // Singleton caches.
    // Avoids prop drilling or Providers.
    // Easy to trace, eays to mock for testing.
    _editorControllerState.setController(controller);
    _scrollControllerState.setController(scrollController);
    _focusNodeState.setFocusNode(focusNode);
    _editorConfigState.setEditorConfig(config);
    _editorWidgetState.setEditor(this);
  }

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
        config: EditorConfigM(
          autoFocus: true,
          readOnly: readOnly,
          keyboardAppearance: keyboardAppearance ?? Brightness.light,
        ),
      );

  @override
  VisualEditorState createState() => VisualEditorState();
}

class VisualEditorState extends State<VisualEditor>
    with
        AutomaticKeepAliveClientMixin<VisualEditor>,
        WidgetsBindingObserver,
        TickerProviderStateMixin<VisualEditor>
    implements TextSelectionDelegate, TextInputClient {
  final _editorState = EditorState();
  final _selectionActionsService = SelectionActionsService();
  final _textSelectionService = TextSelectionService();
  final _editorTextService = EditorTextService();
  final _cursorService = CursorService();
  final _clipboardService = ClipboardService();
  final _textConnectionService = TextConnectionService();
  final _scrollControllerState = ScrollControllerState();
  final _keyboardService = KeyboardService();
  final _keyboardActionsService = KeyboardActionsService();
  final _editorService = EditorService();
  final _editorStateWidgetState = EditorStateWidgetState();
  final _editorConfigState = EditorConfigState();
  final _focusNodeState = FocusNodeState();
  final _documentService = DocumentService();
  final _documentState = DocumentState();
  final _stylesService = StylesService();
  final _textValueService = TextValueService();
  final _selectionLayersState = SelectionLayersState();

  SelectionActionsController? selectionActionsController;
  late FloatingCursorController _floatingCursorController;
  final _editorKey = GlobalKey<State<VisualEditor>>();
  final _editorRendererKey = GlobalKey<State<VisualEditor>>();
  KeyboardVisibilityController? keyboardVisibilityCtrl;
  late final StreamSubscription<bool>? keyboardVisibilitySub;
  bool _didAutoFocus = false;
  DefaultStyles? styles;
  final ClipboardStatusNotifier clipboardStatus = ClipboardStatusNotifier();
  ViewportOffset? _offset;
  late final StreamSubscription editorUpdatesListener;

  TextDirection get textDirection => Directionality.of(context);

  @override
  void initState() {
    super.initState();
    _cacheStateWidget();
    _listedToClipboardAndUpdateEditor();
    _subscribeToEditorUpdates();
    _listenToScrollAndUpdateOverlayMenu();
    _initKeyboard();
    _listenToFocusAndUpdateCaretAndOverlayMenu();
    _floatingCursorController = FloatingCursorController();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    super.build(context);

    _stylesService.getPlatformStylesAndSetCursorControllerOnce(context);

    return _conditionalPreventKeyPropagationToParentIfWeb(
      child: _i18n(
        child: _textGestures(
          child: _documentStyles(
            child: _hotkeysActions(
              child: _focusField(
                child: _keyboardListener(
                  child: _constrainedBox(
                    child: _conditionalScrollable(
                      child: _overlayTargetForMobileToolbar(
                        child: _editorRenderer(
                          children: _documentService.docBlocsAndLines(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentStyles = DocumentStyles.getStyles(context, true);
    final defaultStyles = DefaultStyles.getInstance(context);
    styles = (parentStyles != null)
        ? defaultStyles.merge(parentStyles)
        : defaultStyles;

    if (_editorConfigState.config.customStyles != null) {
      styles = styles!.merge(_editorConfigState.config.customStyles!);
    }

    if (!_didAutoFocus && _editorConfigState.config.autoFocus) {
      FocusScope.of(context).autofocus(_focusNodeState.node);
      _didAutoFocus = true;
    }
  }

  @override
  void dispose() {
    _editorService.disposeEditor();
    super.dispose();
  }

  // === CLIPBOARD OVERRIDES ===

  @override
  void copySelection(SelectionChangedCause cause) {
    _clipboardService.copySelection(cause);
  }

  @override
  void cutSelection(SelectionChangedCause cause) {
    _clipboardService.cutSelection(cause);
  }

  @override
  Future<void> pasteText(SelectionChangedCause cause) async =>
      _clipboardService.pasteText(cause);

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
    _textConnectionService.updateEditingValue(value);
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    _floatingCursorController.updateFloatingCursor(point);
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

  // Required to avoid circular reference between EditorService and KeyboardService.
  // Ugly solution but it works.
  bool hardwareKeyboardEvent(KeyEvent _) =>
      _keyboardService.hardwareKeyboardEvent(_textValueService);

  void refresh() => setState(() {});

  void safeUpdateKeepAlive() => updateKeepAlive();

  // === PRIVATE ===

  GlobalKey<State<VisualEditor>> get editableTextKey => _editorKey;

  Widget _i18n({required Widget child}) => I18n(
        initialLocale: widget.config.locale,
        child: child,
      );

  Widget _textGestures({required Widget child}) => TextGestures(
        behavior: HitTestBehavior.translucent,
        editorRendererKey: _editorRendererKey,
        child: child,
      );

  // Intercept RawKeyEvent on Web to prevent it from propagating to parents that
  // might interfere with the editor key behavior, such as SingleChildScrollView.
  // SingleChildScrollView reacts to keys.
  Widget _conditionalPreventKeyPropagationToParentIfWeb(
          {required Widget child}) =>
      kIsWeb
          ? RawKeyboardListener(
              focusNode: FocusNode(
                onKey: (node, event) => KeyEventResult.skipRemainingHandlers,
              ),
              child: child,
              onKey: (_) {},
            )
          : child;

  Widget _documentStyles({required Widget child}) => DocumentStyles(
        styles: styles!,
        child: child,
      );

  Widget _hotkeysActions({required Widget child}) => Actions(
        actions: _keyboardActionsService.getActions(context),
        child: child,
      );

  Widget _focusField({required Widget child}) => Focus(
        focusNode: _focusNodeState.node,
        child: child,
      );

  Widget _keyboardListener({required Widget child}) => EditorKeyboardListener(
        child: child,
      );

  // Since SingleChildScrollView does not implement `computeDistanceToActualBaseline` it prevents
  // the editor from providing its baseline metrics.
  // To address this issue we wrap the scroll view with BaselineProxy which mimics the editor's baseline.
  // This implies that the first line has no styles applied to it.
  Widget _conditionalScrollable({required Widget child}) =>
      _editorConfigState.config.scrollable
          ? BaselineProxy(
              textStyle: styles!.paragraph!.style,
              padding: EdgeInsets.only(
                top: styles!.paragraph!.verticalSpacing.item1,
              ),
              child: EditorSingleChildScrollView(
                viewportBuilder: (_, offset) {
                  _offset = offset;

                  return child;
                },
              ),
            )
          : child;

  Widget _constrainedBox({required Widget child}) => Container(
        constraints: _editorConfigState.config.expands
            ? const BoxConstraints.expand()
            : BoxConstraints(
                minHeight: _editorConfigState.config.minHeight ?? 0.0,
                maxHeight:
                    _editorConfigState.config.maxHeight ?? double.infinity,
              ),
        child: child,
      );

  // Used by the selection toolbar to position itself in the right location
  Widget _overlayTargetForMobileToolbar({required Widget child}) =>
      CompositedTransformTarget(
        link: _selectionLayersState.toolbarLayerLink,
        child: child,
      );

  Widget _editorRenderer({required List<Widget> children}) => Semantics(
        child: EditorRenderer(
          key: _editorRendererKey,
          offset: _offset,
          document: _getDocOrPlaceholder(),
          textDirection: textDirection,
          children: children,
        ),
      );

  DocumentM _getDocOrPlaceholder() => _documentState.document.isEmpty() &&
          _editorConfigState.config.placeholder != null
      ? DocumentM.fromJson(
          jsonDecode(
            '[{'
            '"attributes":{"placeholder":true},'
            '"insert":"${_editorConfigState.config.placeholder}\\n"'
            '}]',
          ),
        )
      : _documentState.document;

  void _listenToFocusAndUpdateCaretAndOverlayMenu() {
    _focusNodeState.node.addListener(
      _editorService.handleFocusChanged,
    );
  }

  void _initKeyboard() {
    _keyboardService.initKeyboard(_textValueService);
  }

  void _listenToScrollAndUpdateOverlayMenu() {
    _scrollControllerState.controller.addListener(
      _updateSelectionOverlayOnScroll,
    );
  }

  void _subscribeToEditorUpdates() {
    editorUpdatesListener = _editorState.updateEditor$.listen(
      (_) => _textValueService.updateEditor(),
    );
  }

  void _listedToClipboardAndUpdateEditor() {
    clipboardStatus.addListener(onChangedClipboardStatus);
  }

  void _cacheStateWidget() => _editorStateWidgetState.setEditorState(this);

  void _updateSelectionOverlayOnScroll() {
    selectionActionsController?.updateOnScroll();
  }

  void onChangedClipboardStatus() {
    if (!mounted) {
      return;
    }

    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
      // Trigger build and updateChildren.
    });
  }
}
