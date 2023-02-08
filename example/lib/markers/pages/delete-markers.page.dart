import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../shared/const/dimensions.const.dart';
import '../../shared/widgets/demo-page-scaffold.dart';
import '../../shared/widgets/loading.dart';
import '../models/markers-and-scroll-offset.model.dart';
import '../widgets/delete-marker-sidebar.dart';

// For smoke testing. You don't need this in your implementation.
const SCROLLABLE = true;

// Markers can be hidden, when users want to see the clear text but also they
// can be removed independently when the user decides that it is no longer desired.
// This operation will remove the entire marker not only hide it.
// All markers with the same id will be removed.
class DeleteMarkersPage extends StatefulWidget {
  @override
  _DeleteMarkersPageState createState() => _DeleteMarkersPageState();
}

class _DeleteMarkersPageState extends State<DeleteMarkersPage> {
  EditorController? _controller;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  var _cachedMarker = MarkerM(id: '', type: '');
  var _isDeleteButtonVisible = false;

  // (!) This stream is extremely important for maintaining the page performance when updating the delete button positions.
  // The _updateMarkerPosition() method will be called many times per second when scrolling.
  // Therefore we want to avoid at all costs to setState() in the parent DeleteMarkersPage.
  // We will update only the DeleteMarkerButton via the stream.
  // By using this trick we can prevent Flutter from running expensive page updates.
  // We will target our updates only on the area that renders the attachments (far better performance).
  final _markers$ = StreamController<MarkersAndScrollOffset>.broadcast();

  @override
  void initState() {
    _loadDocumentAndInitController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _scaffold(
        children: _controller != null
            ? [
                _flexibleRow(
                  children: [
                    _editor(),
                    _isDeleteButtonVisible
                        ? _deleteMarkerButton()
                        : _deleteButtonPlaceholder()
                  ],
                ),
                _toolbar(),
              ]
            : [
                Loading(),
              ],
      );

  Widget _scaffold({required List<Widget> children}) => DemoPageScaffold(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        ),
      );

  Widget _flexibleRow({required List<Widget> children}) => Flexible(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );

  Widget _deleteMarkerButton() => DeleteMarkerSidebar(
        marker$: _markers$,
        controller: _controller!,
        onTap: _hideDeleteButton,
      );

  Widget _deleteButtonPlaceholder() => Container(width: 40);

  Widget _editor() => Flexible(
        child: Container(
          width: PAGE_WIDTH,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
          child: VisualEditor(
            controller: _controller!,
            // (!) Don't do this mistake.
            // You will override the Scroll controller with a new instance and the scroll callback wont fire.
            scrollController: SCROLLABLE ? _scrollController : null,
            focusNode: _focusNode,
            config: EditorConfigM(
              markerTypes: _getMarkerTypes(),
              // ignore: avoid_redundant_argument_values
              scrollable: SCROLLABLE,
              onBuildComplete: _updateMarker,
              onScroll: _updateMarker,
              onSelectionChanged: (selection) => _hideDeleteButton(),
            ),
          ),
        ),
      );

  Widget _toolbar() => Container(
        padding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        child: EditorToolbar.basic(
          controller: _controller!,
          showMarkers: true,
          multiRowsDisplay: false,
        ),
      );

  // === UTILS ===

  Future<void> _loadDocumentAndInitController() async {
    final deltaJson = await rootBundle.loadString(
      'lib/markers/assets/delete-markers.json',
    );
    final document = DocumentM.fromJson(jsonDecode(deltaJson));

    setState(() {
      _controller = EditorController(
        document: document,
      );
    });
  }

  List<MarkerTypeM> _getMarkerTypes() => [
        MarkerTypeM(
          name: 'Expert',
          id: 'expert',
          color: Colors.amber.withOpacity(0.2),
          onAddMarkerViaToolbar: (_) => 'fake-id-1',
          onSingleTapUp: _displayDeleteButtonOnMarker,
        ),
        MarkerTypeM(
          name: 'Beginner',
          id: 'beginner',
          color: Colors.blue.withOpacity(0.2),
          onAddMarkerViaToolbar: (_) => 'fake-id-2',
          onSingleTapUp: _displayDeleteButtonOnMarker,
        ),
        MarkerTypeM(
          name: 'Reminder',
          id: 'reminder',
          color: Colors.cyan.withOpacity(0.2),
          onAddMarkerViaToolbar: (_) => 'fake-id-3',
          onSingleTapUp: _displayDeleteButtonOnMarker,
        ),
      ];

  void _displayDeleteButtonOnMarker(MarkerM marker) {
    _cachedMarker = marker;
    _displayDeleteButton();
  }

  void _displayDeleteButton() => setState(
        () => _isDeleteButtonVisible = true,
      );

  void _hideDeleteButton() => setState(
        () => _isDeleteButtonVisible = false,
      );

  // From here on it's up to the client developer to decide how to draw the delete buttons.
  // Once you have the build and scroll updates + the pixel coordinates, you can do whatever you want.
  // (!) Inspect the coordinates to draw only the markers that are still visible in the viewport.
  // (!) This method will be invoked many times by the scroll callback.
  // (!) Avoid heavy computations here, otherwise your page might slow down.
  // (!) Avoid setState() on the parent page, setState in a smallest possible widget to minimise the update cost.
  void _updateMarker() {
    _markers$.sink.add(
      MarkersAndScrollOffset(
        markers: [_cachedMarker],
        scrollOffset: SCROLLABLE ? _scrollController.offset : 0,
      ),
    );
  }
}
