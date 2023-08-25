import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/shared/models/selection-rectangles.model.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../interactions/widgets/selection-quick-menu.dart';
import '../../markers/widgets/markers-attachments.dart';
import '../../shared/widgets/demo-page-scaffold.dart';
import '../../shared/widgets/loading.dart';
import '../controllers/marker-attachments.controller.dart';
import '../controllers/selection-menu.controller.dart';

// Demonstrate how features like markers-attachments and selection menu must be implemented
// when we use more non-scrollable editors in a single scrollable parent.
// Like an article page that consists of more topics and every topic is an independent widget and uses an independent editor.
// Every topic can have styling images and other desired features but we want the markers-attachments and the selection
// menu to be synchronized in the whole page (is not useful to have them independent for every editor).
// We have to calculate the relative position of every editor (the position of the editor inside the parent)
// by summing the heights of the widgets above it.
// Every widget will receive a key and then we will query its height.
// For the last editor we don t have to assign a key because there is no more editors to calculate their rel pos based on its height.
// The relative position will be sent to every child of the editor (selection menu, markers-attachments).
// Then every child will calculate its final position using the local position, relative position and
// the page scroll offset (if needed).
// Every time a position is changed we will update all children to keep them synchronized.
// For performance reasons we use streams to inform the children that it is time to update their position
// to avoid using setState on the entire page.
class ParentScrollPage extends StatefulWidget {
  @override
  _ParentScrollPageState createState() => _ParentScrollPageState();
}

class _ParentScrollPageState extends State<ParentScrollPage> {
  final _markerAttachmentsController = MarkerAttachmentsController();
  final _selectionMenuController = SelectionMenuController();
  final _focusNode1 = FocusNode();
  final _focusNode2 = FocusNode();
  final _focusNode3 = FocusNode();
  final _key1 = GlobalKey();
  final _key2 = GlobalKey();
  final _scrollController = ScrollController();
  EditorController? _controller1;
  EditorController? _controller2;
  EditorController? _controller3;
  var _isQuickMenuVisible = false;
  double _editor2RelPos = 0;
  double _editor3RelPos = 0;

  @override
  void initState() {
    _loadDocumentAndInitController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _calculateEditorsRelativePosition();

    return _scaffold(
      child: _controller1 != null
          ? _stack(
              children: [
                _row(
                  children: [
                    _markersAttachments(),
                    _scrollCol(
                      children: [
                        _editor1(),
                        _editor2(),
                        _editor3(),
                      ],
                    ),
                  ],
                ),
                if (_isQuickMenuVisible) _quickMenu(),
                _toolbar(),
              ],
            )
          : Loading(),
    );
  }

  Widget _scaffold({required Widget child}) => DemoPageScaffold(
        child: child,
      );

  Widget _stack({required List<Widget> children}) => Expanded(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: children,
        ),
      );

  Widget _scrollCol({required List<Widget> children}) => Expanded(
        child: NotificationListener(
          onNotification: (_) {
            _updateMarkerAttachments();
            _updateSelectionMenuPositionOnScroll();

            // Return true to cancel the notification bubbling
            return true;
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: children,
            ),
          ),
        ),
      );

  Widget _row({required List<Widget> children}) => Row(
        children: children,
      );

  Widget _markersAttachments() => MarkersAttachments(
        markers$: _markerAttachmentsController.markers$,
      );

  Widget _quickMenu() => SelectionQuickMenu(
        offset: _selectionMenuController.quickMenuOffset,
        offset$: _selectionMenuController.quickMenuOffset$,
      );

  Widget _toolbar() => EditorToolbar.basic(
        controller: _controller1!,
        multiRowsDisplay: false,
      );

  Widget _editor1() => _editor(
        key: _key1,
        controller: _controller1!,
        focusNode: _focusNode1,
        onExtractMarkersCompleted: (markers) {
          _cacheMarkersAndPos(markers, 0);
        },
        onSelectionChanged: (rectangles) {
          _displayQuickMenuOnSelection(rectangles, 0);
        },
        onMarkerTap: (marker) {
          _displayQuickMenuOnMarker(marker, 0);
          _displayQuickMenu();
        },
        onHighlightTap: (highlight) {
          _displayQuickMenuOnHighlight(highlight, 0);
          _displayQuickMenu();
        },
      );

  Widget _editor2() => _editor(
        key: _key2,
        controller: _controller2!,
        focusNode: _focusNode2,
        onExtractMarkersCompleted: (markers) {
          _cacheMarkersAndPos(markers, _editor2RelPos);
        },
        onSelectionChanged: (rectangles) {
          _displayQuickMenuOnSelection(rectangles, _editor2RelPos);
        },
        onMarkerTap: (marker) {
          _displayQuickMenuOnMarker(marker, _editor2RelPos);
          _displayQuickMenu();
        },
        onHighlightTap: (highlight) {
          _displayQuickMenuOnHighlight(highlight, _editor2RelPos);
          _displayQuickMenu();
        },
      );

  Widget _editor3() => _editor(
        controller: _controller3!,
        focusNode: _focusNode3,
        padding: EdgeInsets.fromLTRB(30, 0, 30, 90),
        onExtractMarkersCompleted: (markers) {
          _cacheMarkersAndPos(markers, _editor3RelPos);
        },
        onSelectionChanged: (rectangles) {
          _displayQuickMenuOnSelection(rectangles, _editor3RelPos);
        },
        onMarkerTap: (marker) {
          _displayQuickMenuOnMarker(marker, _editor3RelPos);
          _displayQuickMenu();
        },
        onHighlightTap: (highlight) {
          _displayQuickMenuOnHighlight(highlight, _editor3RelPos);
          _displayQuickMenu();
        },
      );

  Widget _editor({
    required FocusNode focusNode,
    required EditorController controller,
    required Function(MarkerM) onMarkerTap,
    required Function(HighlightM) onHighlightTap,
    required Function(List<SelectionRectanglesM?>) onSelectionChanged,
    required Function(List<MarkerM?>) onExtractMarkersCompleted,
    EdgeInsets? padding,
    GlobalKey? key,
  }) =>
      Container(
        key: key,
        color: Colors.white,
        padding: padding ?? EdgeInsets.fromLTRB(30, 0, 30, 30),
        child: VisualEditor(
          controller: controller,
          focusNode: focusNode,
          config: EditorConfigM(
            scrollable: false,
            placeholder: 'Enter text',
            highlights: _getHighlights(onHighlightTap),
            markerTypes: _getMarkerTypes(onMarkerTap),
            onBuildCompleted: () {
              onExtractMarkersCompleted(controller.getAllMarkers());
              _updateMarkerAttachments();
            },
            onSelectionChanged: (_) {
              _hideQuickMenu();
            },
            onSelectionCompleted: (rectangles) {
              final isCollapsed =
                  rectangles.first?.textSelection.isCollapsed ?? true;

              onSelectionChanged(rectangles);
              if (!isCollapsed) {
                _displayQuickMenu();
              }
            },
          ),
        ),
      );

  Future<void> _loadDocumentAndInitController() async {
    final deltaJson = await rootBundle.loadString(
      'lib/developer/assets/parent-scroll.json',
    );
    final document1 = DeltaDocM.fromJson(jsonDecode(deltaJson)[0]);
    final document2 = DeltaDocM.fromJson(jsonDecode(deltaJson)[1]);
    final document3 = DeltaDocM.fromJson(jsonDecode(deltaJson)[2]);

    setState(() {
      _controller1 = EditorController(
        document: document1,
      );
      _controller2 = EditorController(
        document: document2,
      );
      _controller3 = EditorController(
        document: document3,
      );
    });
  }

// === TYPES ===

  List<MarkerTypeM> _getMarkerTypes(Function(MarkerM) onTap) => [
        MarkerTypeM(
          id: 'expert',
          name: 'Expert',
          color: Colors.amber.withOpacity(0.2),
          onAddMarkerViaToolbar: (_) => 'fake-id-1',
          onSingleTapUp: onTap,
        ),
      ];

  List<HighlightM> _getHighlights(
    Function(HighlightM) onTap,
  ) =>
      [
        HighlightM(
          id: '1255915688987000',
          color: Colors.purpleAccent.withOpacity(0.2),
          textSelection: const TextSelection(
            baseOffset: 160,
            extentOffset: 260,
          ),
          onSingleTapUp: onTap,
        )
      ];

  // === MARKERS ATTACHMENTS ===

  void _cacheMarkersAndPos(
    List<MarkerM?> markers,
    double relPos,
  ) {
    _markerAttachmentsController.cacheMarkersAndRelPos(
      markers: markers,
      relPos: relPos,
    );
  }

  void _updateMarkerAttachments() {
    _markerAttachmentsController.updateMarkerAttachments(
      _scrollController,
    );
  }

  // === SELECTION MENU ===

  void _displayQuickMenu() {
    setState(() {
      _isQuickMenuVisible = true;
    });
  }

  void _displayQuickMenuOnSelection(
    List<SelectionRectanglesM?> rectangles,
    double relPos,
  ) {
    _selectionMenuController.displayQuickMenuOnTextSelection(
      rectangles,
      _scrollController.offset,
      relPos,
    );
  }

  void _displayQuickMenuOnMarker(
    MarkerM marker,
    double relPos,
  ) {
    _selectionMenuController.displayQuickMenuOnMarker(
      marker,
      _scrollController.offset,
      relPos,
    );
  }

  void _displayQuickMenuOnHighlight(
    HighlightM highlight,
    double relPos,
  ) {
    _selectionMenuController.displayQuickMenuOnHighlight(
      highlight,
      _scrollController.offset,
      relPos,
    );
  }

  void _hideQuickMenu() {
    if (_isQuickMenuVisible != false) {
      setState(() {
        _isQuickMenuVisible = false;
      });
    }
  }

  void _updateSelectionMenuPositionOnScroll() {
    _selectionMenuController.updateQuickMenuPositionAfterScroll(
      _scrollController.offset,
    );
  }

  // === UTILS ===

  void _calculateEditorsRelativePosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editor2RelPos = _key1.currentContext?.size?.height ?? 0;
      _editor3RelPos =
          _editor2RelPos + (_key2.currentContext?.size?.height ?? 0);
    });
  }
}
