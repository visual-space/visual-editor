import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/markers/models/marker.model.dart';
import 'package:visual_editor/shared/models/selection-rectangles.model.dart';
import 'package:visual_editor/visual-editor.dart';

import '../widgets/demo-scaffold.dart';
import '../widgets/loading.dart';
import '../widgets/selection-quick-menu.dart';

// Several interactions can render a selection menu:
// - Selecting text
// - Hovering highlights and markers
// The selection menu can actually be any widget you desire.
// (!) To ensure mobile devices have full access to all the app features,
// it is recommended to display additional attachments on tap, not on hover.
// (!) Notice that we are synchronising the position of the quick menu with the scroll offset manually.
// (!) Looking at the demo code one can believe that the current API for managing selection menu is rather complex.
// However, our goal is not to provide a minified toolbars as the selection menu.
// Our goal is to provide an API that is versatile enough to be used for any menu,
// in any position triggered by any conditions you can think of.
// This gives maximum flexibility to implement any kind of UX interactions you might need for your particular app.
// Even the positioning logic was left open for the client developers to best decide what fits them best.
// If all you need is to setup a new button in the custom menu, then try using the custom controls option.
class SelectionMenuPage extends StatefulWidget {
  @override
  _SelectionMenuPageState createState() => _SelectionMenuPageState();
}

class _SelectionMenuPageState extends State<SelectionMenuPage> {
  EditorController? _controller;
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  var _isQuickMenuVisible = false;
  var _cachedRectangle = TextBox.fromLTRBD(0, 0, 0, 0, TextDirection.ltr);
  Offset? _cachedLineOffset = Offset.zero;

  // (!) This stream is extremely important for maintaining the page performance when updating the quick menu position.
  // The _positionQuickMenuAtRectangle() method will be called many times per second when scrolling.
  // Therefore we want to avoid at all costs to setState() in the parent SelectionMenuPage.
  // We will update only the SelectionQuickMenu via the stream.
  // By using this trick we can prevent Flutter from running expensive page updates.
  // We will target our updates only on the area that renders the quick menu (far better performance).
  final _quickMenuOffset$ = StreamController<Offset>.broadcast();
  var _quickMenuOffset = Offset.zero;

  @override
  void initState() {
    _loadDocument();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          DemoScaffold(
            child: _controller != null
                ? _col(
                    children: [
                      _editor(),
                      _toolbar(),
                    ],
                  )
                : Loading(),
          ),
          if (_isQuickMenuVisible) _quickMenu(),
        ],
      );

  Widget _col({required List<Widget> children}) => Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: children,
      );

  Widget _editor() => Flexible(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
          ),
          child: VisualEditor(
            controller: _controller!,
            scrollController: _scrollController,
            focusNode: _focusNode,
            config: EditorConfigM(),
          ),
        ),
      );

  Widget _toolbar() => Container(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        child: EditorToolbar.basic(
          controller: _controller!,
          showMarkers: true,
        ),
      );

  Widget _quickMenu() => SelectionQuickMenu(
        offset: _quickMenuOffset,
        offset$: _quickMenuOffset$,
      );

  // === UTILS ===

  Future<void> _loadDocument() async {
    final result = await rootBundle.loadString(
      'assets/docs/selection-menu.json',
    );
    final document = DocumentM.fromJson(jsonDecode(result));

    setState(() {
      _initEditorController(document);
    });
  }

  void _initEditorController(DocumentM document) {
    _controller = EditorController(
      document: document,
      highlights: [
        HighlightM(
          id: '1255915688987000',
          color: Colors.purpleAccent.withOpacity(0.2),
          textSelection: const TextSelection(
            baseOffset: 30,
            extentOffset: 40,
          ),
          onSingleTapUp: _displayQuickMenuOnHighlight,
        )
      ],
      markerTypes: [
        MarkerTypeM(
          id: 'expert',
          name: 'Expert',
          color: Colors.amber.withOpacity(0.2),
          hoverColor: Colors.amber.withOpacity(0.4),
          onAddMarkerViaToolbar: (type) => 'fake-id-1',
          onSingleTapUp: _displayQuickMenuOnMarker,
        ),
      ],
      onScroll: _updateQuickMenuPosition,
      onSelectionChanged: (selection, rectangles) {
        _hideQuickMenu();
      },
      onSelectionCompleted: (markers) {
        final isCollapsed = _controller?.selection.isCollapsed ?? true;

        // Don't render menu for selections that are collapsed (zero chars selected)
        if (!isCollapsed) {
          _displayQuickMenuOnTextSelection(markers);
        }
      },
    );
  }

  // === QUICK MENU ===
  // (!) To ensure mobile devices have full access to all the app features,
  // it is recommended to display additional attachments on tap, not on hover.
  // (!) This logic could be expanded to include collision detection or
  // to position the attachment in any location desired.

  void _hideQuickMenu() {
    if (_isQuickMenuVisible != false) {
      setState(() {
        _isQuickMenuVisible = false;
      });
    }
  }

  void _displayQuickMenuOnHighlight(HighlightM highlight) {
    final rectangle = highlight.rectanglesByLines![0].rectangles[0];
    final lineOffset = highlight.rectanglesByLines![0].docRelPosition;
    _cachedRectangle = rectangle;
    _cachedLineOffset = lineOffset;
    _positionQuickMenuAtRectangle(_cachedRectangle, _cachedLineOffset);
    _displayQuickMenu();
  }

  void _displayQuickMenuOnMarker(MarkerM marker) {
    final rectangle = marker.rectangles![0];
    final lineOffset = marker.docRelPosition;
    _cachedRectangle = rectangle;
    _cachedLineOffset = lineOffset;
    _positionQuickMenuAtRectangle(_cachedRectangle, _cachedLineOffset);
    _displayQuickMenu();
  }

  void _displayQuickMenuOnTextSelection(
    List<SelectionRectanglesM?> rectanglesByLines,
  ) {
    final noLinesSelected = rectanglesByLines[0] == null;
    final rectanglesAreMissing = rectanglesByLines[0]!.rectangles.isEmpty;

    // Failsafe
    if (noLinesSelected || rectanglesAreMissing) {
      return;
    }

    final rectangle = rectanglesByLines[0]!.rectangles[0];
    final lineOffset = rectanglesByLines[0]!.docRelPosition;

    _cachedRectangle = rectangle;
    _cachedLineOffset = lineOffset;
    _positionQuickMenuAtRectangle(_cachedRectangle, _cachedLineOffset);
    _displayQuickMenu();
  }

  void _displayQuickMenu() {
    setState(() {
      _isQuickMenuVisible = true;
    });
  }

  void _positionQuickMenuAtRectangle(TextBox rectangle, Offset? lineOffset) {
    final hMidPoint = rectangle.left + (rectangle.right - rectangle.left) / 2;
    const menuHeight = 30;
    const menuHalfWidth = 33;

    // Menu Position
    final offset = Offset(
      hMidPoint - menuHalfWidth,
      (lineOffset?.dy ?? 0) +
          rectangle.top -
          _scrollController.offset -
          menuHeight,
    );
    _quickMenuOffset = offset;
    _quickMenuOffset$.sink.add(offset);
  }

  void _updateQuickMenuPosition() {
    if (_isQuickMenuVisible) {
      _positionQuickMenuAtRectangle(_cachedRectangle, _cachedLineOffset);
    }
  }
}
