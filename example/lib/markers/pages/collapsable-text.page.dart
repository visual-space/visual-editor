import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../shared/const/dimensions.const.dart';
import '../../shared/widgets/demo-page-scaffold.dart';
import '../../shared/widgets/loading.dart';
import '../models/marker-and-relative-position.model.dart';
import '../models/markers-attachments-position.dart';
import '../widgets/markers-attachments.dart';

// For smoke testing. You don't need this in your implementation.
const SCROLLABLE = true;

class CollapsableTextPage extends StatefulWidget {
  @override
  _CollapsableTextPageState createState() => _CollapsableTextPageState();
}

class _CollapsableTextPageState extends State<CollapsableTextPage> {
  EditorController? _controller;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  // (!) This stream is extremely important for maintaining the page performance when updating the attachments positions.
  // The _updateMarkerAttachments() method will be called many times per second when scrolling.
  // Therefore we want to avoid at all costs to setState() in the parent MarkersAttachmentsPage.
  // We will update only the MarkersAttachmentsSidebar via the stream.
  // By using this trick we can prevent Flutter from running expensive page updates.
  // We will target our updates only on the area that renders the attachments (far better performance).
  final _markers$ = StreamController<MarkersAttachmentsPos>.broadcast();

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
                    _markersAttachments(),
                    _editor(),
                    _fillerToBalanceRow(),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );

  Widget _markersAttachments() => MarkersAttachments(
        markers$: _markers$,
        onTap: (marker) {
          _controller?.toggleMarkerTextVisibilityByMarkerId(
            marker.id,
            false,
          );
        },
      );

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
              onBuildCompleted: _updateMarkerAttachments,
              onScroll: _updateMarkerAttachments,
            ),
          ),
        ),
      );

  // Row is space in between, therefore we need on the right side an empty container to force the editor on the center.
  Widget _fillerToBalanceRow() => Container(width: 0);

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
      'lib/markers/assets/collapsable-text.json',
    );
    final document = DeltaDocM.fromJson(jsonDecode(deltaJson));

    setState(() {
      _controller = EditorController(
        document: document,
      );
    });
  }

  List<MarkerTypeM> _getMarkerTypes() => [
        MarkerTypeM(
          id: 'extra-info',
          name: 'Extra-Info',
          color: Colors.black.withOpacity(0.2),
          onAddMarkerViaToolbar: (_) => 'fake-id-1',
          onSingleTapUp: (marker) {
            print('Marker Tapped - ${marker.type}');
          },
        )
      ];

  // From here on it's up to the client developer to decide how to draw the attachments.
  // Once you have the build and scroll updates + the pixel coordinates, you can do whatever you want.
  // (!) Inspect the coordinates to draw only the markers that are still visible in the viewport.
  // (!) This method will be invoked many times by the scroll callback.
  // (!) Avoid heavy computations here, otherwise your page might slow down.
  // (!) Avoid setState() on the parent page, setState in a smallest possible widget to minimise the update cost.
  void _updateMarkerAttachments() {
    final markers = _controller?.getAllMarkers() ?? [];
    final markersAndPos = <MarkerAndRelPos>[];

    markers.forEach((marker) {
      markersAndPos.add(
        MarkerAndRelPos(
          marker: marker,
        ),
      );
    });

    _markers$.sink.add(
      MarkersAttachmentsPos(
        markers: markersAndPos,
        scrollOffset: SCROLLABLE ? _scrollController.offset : 0,
      ),
    );
  }
}
