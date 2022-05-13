import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:tuple/tuple.dart';

import '../../blocks/models/custom-builders.type.dart';
import '../../blocks/models/link-action-menu.enum.dart';
import '../../blocks/models/link-action.picker.type.dart';
import '../../blocks/services/default-link-action-picker-delegate.dart';
import '../../blocks/services/default-styles.utils.dart';
import '../../blocks/services/quill-styles.utils.dart';
import '../../blocks/widgets/text-block.dart';
import '../../blocks/widgets/text-line.dart';
import '../../controller/services/controller.dart';
import '../../cursor/models/cursor-style.model.dart';
import '../../cursor/widgets/cursor.dart';
import '../../delta/services/delta.utils.dart';
import '../../documents/models/attribute.dart';
import '../../documents/models/document.dart';
import '../../documents/models/nodes/block.dart';
import '../../documents/models/nodes/embeddable.dart';
import '../../documents/models/nodes/line.dart';
import '../../documents/models/nodes/node.dart';
import '../../documents/models/style.dart';
import '../../embeds/widgets/default-embed-builder.dart';
import '../../embeds/widgets/image.dart';
import '../../inputs/widgets/editor-keyboard-listener.dart';
import '../../selection/services/editor-text-selection-overlay.utils.dart';
import '../../shared/utils/platform.utils.dart';
import '../models/boundaries/character-boundary.model.dart';
import '../models/boundaries/collapse-selection.boundary.model.dart';
import '../models/boundaries/document-boundary.model.dart';
import '../models/boundaries/expanded-text-boundary.dart';
import '../models/boundaries/line-break.model.dart';
import '../models/boundaries/mixed.boundary.model.dart';
import '../models/boundaries/text-boundary.model.dart';
import '../models/boundaries/whitespace-boundary.model.dart';
import '../models/boundaries/word-boundary.model.dart';
import '../models/editor-state.model.dart';
import '../services/actions/copy-selection-action.dart';
import '../services/actions/delete-text-action.dart';
import '../services/actions/extend-selection-or-caret-position-action.dart';
import '../services/actions/select-all-action.dart';
import '../services/actions/update-text-selection-action.dart';
import '../services/actions/update-text-selection-to-adjiacent-line-action.dart';
import 'editor-renderer.dart';
import 'mixins/selection-delegate-mixin.dart';
import 'mixins/text-input-client-mixin.dart';
import 'proxy/baseline-proxy.dart';
import 'raw-editor-renderer.dart';
import 'scroll/quill-single-child-scroll-view.dart';

class RawEditor extends StatefulWidget {
  const RawEditor({
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.scrollBottomInset,
    required this.cursorStyle,
    required this.selectionColor,
    required this.selectionCtrls,
    Key? key,
    this.scrollable = true,
    this.padding = EdgeInsets.zero,
    this.readOnly = false,
    this.placeholder,
    this.onLaunchUrl,
    this.toolbarOptions = const ToolbarOptions(
      copy: true,
      cut: true,
      paste: true,
      selectAll: true,
    ),
    this.showSelectionHandles = false,
    bool? showCursor,
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
        showCursor = showCursor ?? true,
        super(key: key);

  // Controls the document being edited.
  final QuillController controller;

  // Controls whether this editor has keyboard focus.
  final FocusNode focusNode;
  final ScrollController scrollController;
  final bool scrollable;
  final double scrollBottomInset;

  // Additional space around the editor contents.
  final EdgeInsetsGeometry padding;

  // Whether the text can be changed.
  // When this is set to true, the text cannot be modified by any shortcut or keyboard operation. The text is still selectable.
  final bool readOnly;

  final String? placeholder;

  // Callback which is triggered when the user wants to open a URL from
  // a link in the document.
  final ValueChanged<String>? onLaunchUrl;

  // Configuration of buttons options.
  //
  // By default, all options are enabled. If [readOnly] is true,
  // paste and cut will be disabled regardless.
  final ToolbarOptions toolbarOptions;

  // Whether to show selection handles.
  //
  // When a selection is active, there will be two handles at each side of
  // boundary, or one handle if the selection is collapsed. The handles can be
  // dragged to adjust the selection.
  //
  // See also:
  //
  //  * [showCursor], which controls the visibility of the cursor.
  final bool showSelectionHandles;

  // Whether to show cursor.
  //
  // The cursor refers to the blinking caret when the editor is focused.
  //
  // See also:
  //
  //  * [cursorStyle], which controls the cursor visual representation.
  //  * [showSelectionHandles], which controls the visibility of the selection
  //    handles.
  final bool showCursor;

  // The style to be used for the editing cursor.
  final CursorStyle cursorStyle;

  // Configures how the platform keyboard will select an uppercase or
  // lowercase keyboard.
  //
  // Only supports text keyboards, other keyboard types will ignore this
  // configuration. Capitalization is locale-aware.
  //
  // Defaults to [TextCapitalization.none]. Must not be null.
  //
  // See also:
  //
  //  * [TextCapitalization], for a description of each capitalization behavior
  final TextCapitalization textCapitalization;

  // The maximum height this editor can have.
  //
  // If this is null then there is no limit to the editor's height and it will
  // expand to fill its parent.
  final double? maxHeight;

  // The minimum height this editor can have.
  final double? minHeight;

  // The maximum width to be occupied by the blocks of this editor.
  //
  // If this is not null and and this editor's width is larger than this value
  // then the contents will be constrained to the provided maximum width and
  // horizontally centered. This is mostly useful on devices with wide screens.
  final double? maxContentWidth;

  final DefaultStyles? customStyles;

  // Whether this widget's height will be sized to fill its parent.
  //
  // If set to true and wrapped in a parent widget like [Expanded] or
  //
  // Defaults to false.
  final bool expands;

  // Whether this editor should focus itself if nothing else is already
  // focused.
  //
  // If true, the keyboard will open as soon as this text field obtains focus.
  // Otherwise, the keyboard is only shown after the user taps the text field.
  //
  // Defaults to false. Cannot be null.
  final bool autoFocus;

  // The color to use when painting the selection.
  final Color selectionColor;

  // Delegate for building the text selection handles and buttons.
  //
  // The [RawEditor] widget used on its own will not trigger the display
  // of the selection buttons by itself. The buttons is shown by calling
  // [RawEditorState.showToolbar] in response to an appropriate user event.
  final TextSelectionControls selectionCtrls;

  // The appearance of the keyboard.
  //
  // This setting is only honored on iOS devices.
  //
  // Defaults to [Brightness.light].
  final Brightness keyboardAppearance;

  // If true, then long-pressing this TextField will select text and show the
  // cut/copy/paste menu, and tapping will move the text caret.
  //
  // True by default.
  //
  // If false, most of the accessibility support for selecting text, copy
  // and paste, and moving the caret will be disabled.
  final bool enableInteractiveSelection;

  bool get selectionEnabled => enableInteractiveSelection;

  // The [ScrollPhysics] to use when vertically scrolling the input.
  //
  // If not specified, it will behave according to the current platform.
  //
  // See [Scrollable.physics].
  final ScrollPhysics? scrollPhysics;

  // Builder function for embeddable objects.
  final EmbedBuilder embedBuilder;
  final LinkActionPickerDelegate linkActionPickerDelegate;
  final CustomStyleBuilder? customStyleBuilder;
  final bool floatingCursorDisabled;

  @override
  State<StatefulWidget> createState() => RawEditorState();
}

class RawEditorState extends EditorState
    with
        AutomaticKeepAliveClientMixin<RawEditor>,
        WidgetsBindingObserver,
        TickerProviderStateMixin<RawEditor>,
        RawEditorStateTextInputClientMixin,
        RawEditorStateSelectionDelegateMixin {
  final GlobalKey _editorKey = GlobalKey();

  KeyboardVisibilityController? _keyboardVisibilityController;
  StreamSubscription<bool>? _keyboardVisibilitySubscription;
  bool _keyboardVisible = false;

  // Selection overlay
  @override
  EditorTextSelectionOverlay? get selectionOverlay => _selectionOverlay;
  EditorTextSelectionOverlay? _selectionOverlay;

  @override
  ScrollController get scrollController => _scrollController;
  late ScrollController _scrollController;

  // Cursors
  late CursorCont _cursorCont;

  QuillController get controller => widget.controller;

  // Focus
  bool _didAutoFocus = false;

  bool get _hasFocus => widget.focusNode.hasFocus;

  // Theme
  DefaultStyles? _styles;

  // for pasting style
  @override
  List<Tuple2<int, Style>> get pasteStyle => _pasteStyle;
  List<Tuple2<int, Style>> _pasteStyle = <Tuple2<int, Style>>[];

  @override
  String get pastePlainText => _pastePlainText;
  String _pastePlainText = '';

  final ClipboardStatusNotifier _clipboardStatus = ClipboardStatusNotifier();
  final LayerLink _toolbarLayerLink = LayerLink();
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();

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
      link: _toolbarLayerLink,
      child: Semantics(
        child: RawEditorRenderer(
          key: _editorKey,
          document: _doc,
          selection: widget.controller.selection,
          hasFocus: _hasFocus,
          scrollable: widget.scrollable,
          cursorController: _cursorCont,
          textDirection: _textDirection,
          startHandleLayerLink: _startHandleLayerLink,
          endHandleLayerLink: _endHandleLayerLink,
          onSelectionChanged: _handleSelectionChanged,
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
      // Since [SingleChildScrollView] does not implement
      // `computeDistanceToActualBaseline` it prevents the editor from
      // providing its baseline metrics. To address this issue we wrap
      // the scroll view with [BaselineProxy] which mimics the editor's
      // baseline.
      // This implies that the first line has no styles applied to it.
      final baselinePadding = EdgeInsets.only(
        top: _styles!.paragraph!.verticalSpacing.item1,
      );
      wrappedEditor = BaselineProxy(
        textStyle: _styles!.paragraph!.style,
        padding: baselinePadding,
        child: QuillSingleChildScrollView(
          controller: _scrollController,
          physics: widget.scrollPhysics,
          viewportBuilder: (_, offset) => CompositedTransformTarget(
            link: _toolbarLayerLink,
            child: RawEditorRenderer(
              key: _editorKey,
              offset: offset,
              document: _doc,
              selection: widget.controller.selection,
              hasFocus: _hasFocus,
              scrollable: widget.scrollable,
              textDirection: _textDirection,
              startHandleLayerLink: _startHandleLayerLink,
              endHandleLayerLink: _endHandleLayerLink,
              onSelectionChanged: _handleSelectionChanged,
              onSelectionCompleted: _handleSelectionCompleted,
              scrollBottomInset: widget.scrollBottomInset,
              padding: widget.padding,
              maxContentWidth: widget.maxContentWidth,
              cursorController: _cursorCont,
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

    return QuillStyles(
      data: _styles!,
      child: Actions(
        actions: _actions,
        child: Focus(
          focusNode: widget.focusNode,
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

  void _handleSelectionChanged(
    TextSelection selection,
    SelectionChangedCause cause,
  ) {
    final oldSelection = widget.controller.selection;
    widget.controller.updateSelection(selection, ChangeSource.LOCAL);

    _selectionOverlay?.handlesVisible = _shouldShowSelectionHandles();

    if (!_keyboardVisible) {
      // This will show the keyboard for all selection changes on the
      // editor, not just changes triggered by user gestures.
      requestKeyboard();
    }

    if (cause == SelectionChangedCause.drag) {
      // When user updates the selection while dragging make sure to
      // bring the updated position (base or extent) into view.
      if (oldSelection.baseOffset != selection.baseOffset) {
        bringIntoView(selection.base);
      } else if (oldSelection.extentOffset != selection.extentOffset) {
        bringIntoView(selection.extent);
      }
    }
  }

  void _handleSelectionCompleted() {
    widget.controller.onSelectionCompleted?.call();
  }

  // Updates the checkbox positioned at [offset] in document
  // by changing its attribute according to [value].
  void _handleCheckboxTap(int offset, bool value) {
    if (!widget.readOnly) {
      _disableScrollControllerAnimateOnce = true;
      final attribute = value ? Attribute.checked : Attribute.unchecked;

      widget.controller.formatText(offset, 0, attribute);

      // Checkbox tapping causes controller.selection to go to offset 0
      // Stop toggling those two buttons buttons
      widget.controller.toolbarButtonToggler = {
        Attribute.list.key: attribute,
        Attribute.header.key: Attribute.header
      };

      // Go back from offset 0 to current selection
      SchedulerBinding.instance!.addPostFrameCallback((_) {
        widget.controller.updateSelection(
            TextSelection.collapsed(offset: offset), ChangeSource.LOCAL);
      });
    }
  }

  List<Widget> _buildChildren(Document doc, BuildContext context) {
    final result = <Widget>[];
    final indentLevelCounts = <int, int>{};
    for (final node in doc.root.children) {
      if (node is Line) {
        final editableTextLine = _getEditableTextLineFromNode(node, context);
        result.add(Directionality(
            textDirection: getDirectionOfNode(node), child: editableTextLine));
      } else if (node is Block) {
        final attrs = node.style.attributes;
        final editableTextBlock = EditableTextBlock(
          block: node,
          controller: widget.controller,
          textDirection: _textDirection,
          scrollBottomInset: widget.scrollBottomInset,
          verticalSpacing: _getVerticalSpacingForBlock(node, _styles),
          textSelection: widget.controller.selection,
          color: widget.selectionColor,
          styles: _styles,
          enableInteractiveSelection: widget.enableInteractiveSelection,
          hasFocus: _hasFocus,
          contentPadding: attrs.containsKey(Attribute.codeBlock.key)
              ? const EdgeInsets.all(16)
              : null,
          embedBuilder: widget.embedBuilder,
          linkActionPicker: _linkActionPicker,
          onLaunchUrl: widget.onLaunchUrl,
          cursorCont: _cursorCont,
          indentLevelCounts: indentLevelCounts,
          onCheckboxTap: _handleCheckboxTap,
          readOnly: widget.readOnly,
          customStyleBuilder: widget.customStyleBuilder,
        );
        result.add(Directionality(
            textDirection: getDirectionOfNode(node), child: editableTextBlock));
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
      verticalSpacing: _getVerticalSpacingForLine(node, _styles),
      textDirection: _textDirection,
      textSelection: widget.controller.selection,
      color: widget.selectionColor,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      hasFocus: _hasFocus,
      devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
      cursorCont: _cursorCont,
    );
    return editableTextLine;
  }

  Tuple2<double, double> _getVerticalSpacingForLine(
      Line line, DefaultStyles? defaultStyles) {
    final attrs = line.style.attributes;
    if (attrs.containsKey(Attribute.header.key)) {
      final int? level = attrs[Attribute.header.key]!.value;
      switch (level) {
        case 1:
          return defaultStyles!.h1!.verticalSpacing;
        case 2:
          return defaultStyles!.h2!.verticalSpacing;
        case 3:
          return defaultStyles!.h3!.verticalSpacing;
        default:
          throw 'Invalid level $level';
      }
    }

    return defaultStyles!.paragraph!.verticalSpacing;
  }

  Tuple2<double, double> _getVerticalSpacingForBlock(
      Block node, DefaultStyles? defaultStyles) {
    final attrs = node.style.attributes;
    if (attrs.containsKey(Attribute.blockQuote.key)) {
      return defaultStyles!.quote!.verticalSpacing;
    } else if (attrs.containsKey(Attribute.codeBlock.key)) {
      return defaultStyles!.code!.verticalSpacing;
    } else if (attrs.containsKey(Attribute.indent.key)) {
      return defaultStyles!.indent!.verticalSpacing;
    } else if (attrs.containsKey(Attribute.list.key)) {
      return defaultStyles!.lists!.verticalSpacing;
    } else if (attrs.containsKey(Attribute.align.key)) {
      return defaultStyles!.align!.verticalSpacing;
    }
    return const Tuple2(0, 0);
  }

  @override
  void initState() {
    super.initState();

    _clipboardStatus.addListener(_onChangedClipboardStatus);

    widget.controller.addListener(() {
      _didChangeTextEditingValue(widget.controller.ignoreFocusOnTextChange);
    });

    _scrollController = widget.scrollController;
    _scrollController.addListener(_updateSelectionOverlayForScroll);

    _cursorCont = CursorCont(
      show: ValueNotifier<bool>(widget.showCursor),
      style: widget.cursorStyle,
      tickerProvider: this,
    );

    // Floating cursor
    _floatingCursorResetController = AnimationController(vsync: this);
    _floatingCursorResetController.addListener(onFloatingCursorResetTick);

    if (isKeyboardOS()) {
      _keyboardVisible = true;
    } else {
      // treat iOS Simulator like a keyboard OS
      isIOSSimulator().then((isIosSimulator) {
        if (isIosSimulator) {
          _keyboardVisible = true;
        } else {
          _keyboardVisibilityController = KeyboardVisibilityController();
          _keyboardVisible = _keyboardVisibilityController!.isVisible;
          _keyboardVisibilitySubscription =
              _keyboardVisibilityController?.onChange.listen((visible) {
            _keyboardVisible = visible;
            if (visible) {
              _onChangeTextEditingValue(!_hasFocus);
            }
          });

          HardwareKeyboard.instance.addHandler(_hardwareKeyboardEvent);
        }
      });
    }

    // Focus
    widget.focusNode.addListener(_handleFocusChanged);
  }

  // KeyboardVisibilityController only checks for keyboards that
  // adjust the screen size. Also watch for hardware keyboards
  // that don't alter the screen (i.e. Chromebook, Android tablet
  // and any hardware keyboards from an OS not listed in isKeyboardOS())
  bool _hardwareKeyboardEvent(KeyEvent _) {
    if (!_keyboardVisible) {
      // hardware keyboard key pressed. Set visibility to true
      _keyboardVisible = true;
      // update the editor
      _onChangeTextEditingValue(!_hasFocus);
    }

    // remove the key handler - it's no longer needed. If
    // KeyboardVisibilityController clears visibility, it wil
    // also enable it when appropriate.
    HardwareKeyboard.instance.removeHandler(_hardwareKeyboardEvent);

    // we didn't handle the event, just needed to know a key was pressed
    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentStyles = QuillStyles.getStyles(context, true);
    final defaultStyles = DefaultStyles.getInstance(context);
    _styles = (parentStyles != null)
        ? defaultStyles.merge(parentStyles)
        : defaultStyles;

    if (widget.customStyles != null) {
      _styles = _styles!.merge(widget.customStyles!);
    }

    if (!_didAutoFocus && widget.autoFocus) {
      FocusScope.of(context).autofocus(widget.focusNode);
      _didAutoFocus = true;
    }
  }

  @override
  void didUpdateWidget(RawEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    _cursorCont.show.value = widget.showCursor;
    _cursorCont.style = widget.cursorStyle;

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_didChangeTextEditingValue);
      widget.controller.addListener(_didChangeTextEditingValue);
      updateRemoteValueIfNeeded();
    }

    if (widget.scrollController != _scrollController) {
      _scrollController.removeListener(_updateSelectionOverlayForScroll);
      _scrollController = widget.scrollController;
      _scrollController.addListener(_updateSelectionOverlayForScroll);
    }

    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
      updateKeepAlive();
    }

    if (widget.controller.selection != oldWidget.controller.selection) {
      _selectionOverlay?.update(textEditingValue);
    }

    _selectionOverlay?.handlesVisible = _shouldShowSelectionHandles();
    if (!shouldCreateInputConnection) {
      closeConnectionIfNeeded();
    } else {
      if (oldWidget.readOnly && _hasFocus) {
        openConnectionIfNeeded();
      }
    }

    // in case customStyles changed in new widget
    if (widget.customStyles != null) {
      _styles = _styles!.merge(widget.customStyles!);
    }
  }

  bool _shouldShowSelectionHandles() {
    return widget.showSelectionHandles &&
        !widget.controller.selection.isCollapsed;
  }

  @override
  void dispose() {
    closeConnectionIfNeeded();
    _keyboardVisibilitySubscription?.cancel();
    HardwareKeyboard.instance.removeHandler(_hardwareKeyboardEvent);
    assert(!hasConnection);
    _selectionOverlay?.dispose();
    _selectionOverlay = null;
    widget.controller.removeListener(_didChangeTextEditingValue);
    widget.focusNode.removeListener(_handleFocusChanged);
    _cursorCont.dispose();
    _clipboardStatus
      ..removeListener(_onChangedClipboardStatus)
      ..dispose();
    super.dispose();
  }

  void _updateSelectionOverlayForScroll() {
    _selectionOverlay?.updateForScroll();
  }

  void _didChangeTextEditingValue([bool ignoreFocus = false]) {
    if (kIsWeb) {
      _onChangeTextEditingValue(ignoreFocus);
      if (!ignoreFocus) {
        requestKeyboard();
      }
      return;
    }

    if (ignoreFocus || _keyboardVisible) {
      _onChangeTextEditingValue(ignoreFocus);
    } else {
      requestKeyboard();
      if (mounted) {
        setState(() {
          // Use widget.controller.value in build()
          // Trigger build and updateChildren
        });
      }
    }

    _adjacentLineAction.stopCurrentVerticalRunIfSelectionChanges();
  }

  void _onChangeTextEditingValue([bool ignoreCaret = false]) {
    updateRemoteValueIfNeeded();
    if (ignoreCaret) {
      return;
    }
    _showCaretOnScreen();
    _cursorCont.startOrStopCursorTimerIfNeeded(
        _hasFocus, widget.controller.selection);
    if (hasConnection) {
      // To keep the cursor from blinking while typing, we want to restart the
      // cursor timer every time a new character is typed.
      _cursorCont
        ..stopCursorTimer(resetCharTicks: false)
        ..startCursorTimer();
    }

    // Refresh selection overlay after the build step had a chance to
    // update and register all children of RenderEditor. Otherwise this will
    // fail in situations where a new line of text is entered, which adds
    // a new RenderEditableBox child. If we try to update selection overlay
    // immediately it'll not be able to find the new child since it hasn't been
    // built yet.
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _updateOrDisposeSelectionOverlayIfNeeded();
    });
    if (mounted) {
      setState(() {
        // Use widget.controller.value in build()
        // Trigger build and updateChildren
      });
    }
  }

  void _updateOrDisposeSelectionOverlayIfNeeded() {
    if (_selectionOverlay != null) {
      if (!_hasFocus || textEditingValue.selection.isCollapsed) {
        _selectionOverlay!.dispose();
        _selectionOverlay = null;
      } else {
        _selectionOverlay!.update(textEditingValue);
      }
    } else if (_hasFocus) {
      _selectionOverlay = EditorTextSelectionOverlay(
        value: textEditingValue,
        context: context,
        debugRequiredFor: widget,
        toolbarLayerLink: _toolbarLayerLink,
        startHandleLayerLink: _startHandleLayerLink,
        endHandleLayerLink: _endHandleLayerLink,
        renderObject: renderEditor,
        selectionCtrls: widget.selectionCtrls,
        selectionDelegate: this,
        clipboardStatus: _clipboardStatus,
      );
      _selectionOverlay!.handlesVisible = _shouldShowSelectionHandles();
      _selectionOverlay!.showHandles();
    }
  }

  void _handleFocusChanged() {
    openOrCloseConnection();
    _cursorCont.startOrStopCursorTimerIfNeeded(
        _hasFocus, widget.controller.selection);
    _updateOrDisposeSelectionOverlayIfNeeded();
    if (_hasFocus) {
      WidgetsBinding.instance!.addObserver(this);
      _showCaretOnScreen();
    } else {
      WidgetsBinding.instance!.removeObserver(this);
    }
    updateKeepAlive();
  }

  void _onChangedClipboardStatus() {
    if (!mounted) return;
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
      // Trigger build and updateChildren
    });
  }

  Future<LinkMenuAction> _linkActionPicker(Node linkNode) async {
    final link = linkNode.style.attributes[Attribute.link.key]!.value!;
    return widget.linkActionPickerDelegate(context, link, linkNode);
  }

  bool _showCaretOnScreenScheduled = false;

  // This is a workaround for checkbox tapping issue
  // https://github.com/singerdmx/flutter-quill/issues/619
  // We cannot treat {"list": "checked"} and {"list": "unchecked"} as
  // block of the same style
  // This causes controller.selection to go to offset 0
  bool _disableScrollControllerAnimateOnce = false;

  void _showCaretOnScreen() {
    if (!widget.showCursor || _showCaretOnScreenScheduled) {
      return;
    }

    _showCaretOnScreenScheduled = true;
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      if (widget.scrollable || _scrollController.hasClients) {
        _showCaretOnScreenScheduled = false;

        if (!mounted) {
          return;
        }

        final viewport = RenderAbstractViewport.of(renderEditor);
        final editorOffset =
            renderEditor.localToGlobal(const Offset(0, 0), ancestor: viewport);
        final offsetInViewport = _scrollController.offset + editorOffset.dy;

        final offset = renderEditor.getOffsetToRevealCursor(
          _scrollController.position.viewportDimension,
          _scrollController.offset,
          offsetInViewport,
        );

        if (offset != null) {
          if (_disableScrollControllerAnimateOnce) {
            _disableScrollControllerAnimateOnce = false;
            return;
          }
          _scrollController.animateTo(
            math.min(offset, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 100),
            curve: Curves.fastOutSlowIn,
          );
        }
      }
    });
  }

  // The renderer for this widget's editor descendant.
  //
  // This property is typically used to notify the renderer of input gestures.
  @override
  RenderEditor get renderEditor =>
      _editorKey.currentContext!.findRenderObject() as RenderEditor;

  // Express interest in interacting with the keyboard.
  //
  // If this control is already attached to the keyboard, this function will
  // request that the keyboard become visible. Otherwise, this function will
  // ask the focus system that it become focused. If successful in acquiring
  // focus, the control will then attach to the keyboard and request that the
  // keyboard become visible.
  @override
  void requestKeyboard() {
    if (_hasFocus) {
      openConnectionIfNeeded();
      _showCaretOnScreen();
    } else {
      widget.focusNode.requestFocus();
    }
  }

  // Shows the selection buttons at the location of the current cursor.
  // Returns `false` if a buttons couldn't be shown, such as when the buttons is already shown,
  // or when no text selection currently exists.
  @override
  bool showToolbar() {
    // Web is using native dom elements to enable clipboard functionality of the buttons: copy, paste, select, cut.
    // It might also provide additional functionality depending on the browser (such as translate).
    // Due to this we should not show Flutter buttons for the editable text elements.
    if (kIsWeb) {
      return false;
    }
    if (_selectionOverlay == null || _selectionOverlay!.toolbar != null) {
      return false;
    }

    _selectionOverlay!.update(textEditingValue);
    _selectionOverlay!.showToolbar();
    return true;
  }

  void _replaceText(ReplaceTextIntent intent) {
    userUpdateTextEditingValue(
      intent.currentTextEditingValue
          .replaced(intent.replacementRange, intent.replacementText),
      intent.cause,
    );
  }

  // Copy current selection to [Clipboard].
  @override
  void copySelection(SelectionChangedCause cause) {
    widget.controller.copiedImageUrl = null;
    _pastePlainText = widget.controller.getPlainText();
    _pasteStyle = widget.controller.getAllIndividualSelectionStyles();

    final selection = textEditingValue.selection;
    final text = textEditingValue.text;
    if (selection.isCollapsed) {
      return;
    }
    Clipboard.setData(ClipboardData(text: selection.textInside(text)));

    if (cause == SelectionChangedCause.toolbar) {
      bringIntoView(textEditingValue.selection.extent);

      // Collapse the selection and hide the buttons and handles.
      userUpdateTextEditingValue(
        TextEditingValue(
          text: textEditingValue.text,
          selection:
              TextSelection.collapsed(offset: textEditingValue.selection.end),
        ),
        SelectionChangedCause.toolbar,
      );
    }
  }

  // Cut current selection to [Clipboard].
  @override
  void cutSelection(SelectionChangedCause cause) {
    widget.controller.copiedImageUrl = null;
    _pastePlainText = widget.controller.getPlainText();
    _pasteStyle = widget.controller.getAllIndividualSelectionStyles();

    if (widget.readOnly) {
      return;
    }
    final selection = textEditingValue.selection;
    final text = textEditingValue.text;
    if (selection.isCollapsed) {
      return;
    }
    Clipboard.setData(ClipboardData(text: selection.textInside(text)));
    _replaceText(ReplaceTextIntent(textEditingValue, '', selection, cause));

    if (cause == SelectionChangedCause.toolbar) {
      bringIntoView(textEditingValue.selection.extent);
      hideToolbar();
    }
  }

  // Paste text from [Clipboard].
  @override
  Future<void> pasteText(SelectionChangedCause cause) async {
    if (widget.readOnly) {
      return;
    }

    if (widget.controller.copiedImageUrl != null) {
      final index = textEditingValue.selection.baseOffset;
      final length = textEditingValue.selection.extentOffset - index;
      final copied = widget.controller.copiedImageUrl!;
      widget.controller
          .replaceText(index, length, BlockEmbed.image(copied.item1), null);
      if (copied.item2.isNotEmpty) {
        widget.controller.formatText(
            getImageNode(widget.controller, index + 1).item1,
            1,
            StyleAttribute(copied.item2));
      }
      widget.controller.copiedImageUrl = null;
      await Clipboard.setData(const ClipboardData(text: ''));
      return;
    }

    final selection = textEditingValue.selection;
    if (!selection.isValid) {
      return;
    }
    // Snapshot the input before using `await`.
    // See https://github.com/flutter/flutter/issues/11427
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null) {
      return;
    }

    _replaceText(
        ReplaceTextIntent(textEditingValue, data.text!, selection, cause));

    bringIntoView(textEditingValue.selection.extent);

    // Collapse the selection and hide the buttons and handles.
    userUpdateTextEditingValue(
      TextEditingValue(
        text: textEditingValue.text,
        selection:
            TextSelection.collapsed(offset: textEditingValue.selection.end),
      ),
      cause,
    );
  }

  // Select the entire text value.
  @override
  void selectAll(SelectionChangedCause cause) {
    userUpdateTextEditingValue(
      textEditingValue.copyWith(
        selection: TextSelection(
            baseOffset: 0, extentOffset: textEditingValue.text.length),
      ),
      cause,
    );

    if (cause == SelectionChangedCause.toolbar) {
      bringIntoView(textEditingValue.selection.extent);
    }
  }

  @override
  bool get wantKeepAlive => widget.focusNode.hasFocus;

  @override
  AnimationController get floatingCursorResetController =>
      _floatingCursorResetController;

  late AnimationController _floatingCursorResetController;

  // === TEXT EDITING ACTIONS ===

  TextBoundaryM _characterBoundary(DirectionalTextEditingIntent intent) {
    final TextBoundaryM atomicTextBoundary =
        CharacterBoundary(textEditingValue);
    return CollapsedSelectionBoundary(atomicTextBoundary, intent.forward);
  }

  TextBoundaryM _nextWordBoundary(DirectionalTextEditingIntent intent) {
    final TextBoundaryM atomicTextBoundary;
    final TextBoundaryM boundary;

    // final TextEditingValue textEditingValue =
    //     _textEditingValueforTextLayoutMetrics;
    atomicTextBoundary = CharacterBoundary(textEditingValue);
    // This isn't enough. Newline characters.
    boundary = ExpandedTextBoundary(WhitespaceBoundary(textEditingValue),
        WordBoundary(renderEditor, textEditingValue));

    final mixedBoundary = intent.forward
        ? MixedBoundary(atomicTextBoundary, boundary)
        : MixedBoundary(boundary, atomicTextBoundary);
    // Use a _MixedBoundary to make sure we don't leave invalid codepoints in
    // the field after deletion.
    return CollapsedSelectionBoundary(mixedBoundary, intent.forward);
  }

  TextBoundaryM _linebreak(DirectionalTextEditingIntent intent) {
    final TextBoundaryM atomicTextBoundary;
    final TextBoundaryM boundary;

    // final TextEditingValue textEditingValue =
    //     _textEditingValueforTextLayoutMetrics;
    atomicTextBoundary = CharacterBoundary(textEditingValue);
    boundary = LineBreak(renderEditor, textEditingValue);

    // The _MixedBoundary is to make sure we don't leave invalid code units in
    // the field after deletion.
    // `boundary` doesn't need to be wrapped in a _CollapsedSelectionBoundary,
    // since the document boundary is unique and the linebreak boundary is
    // already caret-location based.
    return intent.forward
        ? MixedBoundary(
            CollapsedSelectionBoundary(
              atomicTextBoundary,
              true,
            ),
            boundary,
          )
        : MixedBoundary(
            boundary,
            CollapsedSelectionBoundary(
              atomicTextBoundary,
              false,
            ),
          );
  }

  TextBoundaryM _documentBoundary(DirectionalTextEditingIntent intent) =>
      DocumentBoundary(textEditingValue);

  Action<T> _makeOverridable<T extends Intent>(Action<T> defaultAction) {
    return Action<T>.overridable(
        context: context, defaultAction: defaultAction);
  }

  late final Action<ReplaceTextIntent> _replaceTextAction =
      CallbackAction<ReplaceTextIntent>(onInvoke: _replaceText);

  void _updateSelection(UpdateSelectionIntent intent) {
    userUpdateTextEditingValue(
      intent.currentTextEditingValue.copyWith(selection: intent.newSelection),
      intent.cause,
    );
  }

  late final Action<UpdateSelectionIntent> _updateSelectionAction =
      CallbackAction<UpdateSelectionIntent>(
    onInvoke: _updateSelection,
  );

  late final UpdateTextSelectionToAdjacentLineAction<
          ExtendSelectionVerticallyToAdjacentLineIntent> _adjacentLineAction =
      UpdateTextSelectionToAdjacentLineAction<
          ExtendSelectionVerticallyToAdjacentLineIntent>(this);

  late final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    DoNothingAndStopPropagationTextIntent: DoNothingAction(consumesKey: false),
    ReplaceTextIntent: _replaceTextAction,
    UpdateSelectionIntent: _updateSelectionAction,
    DirectionalFocusIntent: DirectionalFocusAction.forTextField(),

    // Delete
    DeleteCharacterIntent: _makeOverridable(
      DeleteTextAction<DeleteCharacterIntent>(
        this,
        _characterBoundary,
      ),
    ),
    DeleteToNextWordBoundaryIntent: _makeOverridable(
      DeleteTextAction<DeleteToNextWordBoundaryIntent>(
        this,
        _nextWordBoundary,
      ),
    ),
    DeleteToLineBreakIntent: _makeOverridable(
      DeleteTextAction<DeleteToLineBreakIntent>(
        this,
        _linebreak,
      ),
    ),

    // Extend/Move Selection
    ExtendSelectionByCharacterIntent: _makeOverridable(
      UpdateTextSelectionAction<ExtendSelectionByCharacterIntent>(
        this,
        false,
        _characterBoundary,
      ),
    ),
    ExtendSelectionToNextWordBoundaryIntent: _makeOverridable(
      UpdateTextSelectionAction<ExtendSelectionToNextWordBoundaryIntent>(
        this,
        true,
        _nextWordBoundary,
      ),
    ),
    ExtendSelectionToLineBreakIntent: _makeOverridable(
      UpdateTextSelectionAction<ExtendSelectionToLineBreakIntent>(
        this,
        true,
        _linebreak,
      ),
    ),
    ExtendSelectionVerticallyToAdjacentLineIntent: _makeOverridable(
      _adjacentLineAction,
    ),
    ExtendSelectionToDocumentBoundaryIntent: _makeOverridable(
      UpdateTextSelectionAction<ExtendSelectionToDocumentBoundaryIntent>(
        this,
        true,
        _documentBoundary,
      ),
    ),
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent: _makeOverridable(
      ExtendSelectionOrCaretPositionAction(
        this,
        _nextWordBoundary,
      ),
    ),

    // Copy Paste
    SelectAllTextIntent: _makeOverridable(
      SelectAllAction(this),
    ),
    CopySelectionTextIntent: _makeOverridable(
      CopySelectionAction(this),
    ),
    PasteTextIntent: _makeOverridable(
      CallbackAction<PasteTextIntent>(
        onInvoke: (intent) => pasteText(intent.cause),
      ),
    ),
  };
}
