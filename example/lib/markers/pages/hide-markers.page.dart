import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/shared/widgets/default-button.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../shared/const/dimensions.const.dart';
import '../../shared/widgets/demo-page-scaffold.dart';
import '../../shared/widgets/loading.dart';
import '../models/marker-and-relative-position.model.dart';
import '../models/markers-attachments-position.dart';
import '../widgets/markers-attachments.dart';
import 'delete-markers.page.dart';

// Markers rectangles can be hidden by type from the document.
// Markers are not deleted so we still can use their information
// i.e. even though the markers are hidden, markers attachments still works properly
class HideMarkersPage extends StatefulWidget {
  @override
  _HideMarkersPageState createState() => _HideMarkersPageState();
}

class _HideMarkersPageState extends State<HideMarkersPage> {
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
                _row(
                  children: [
                    _toggleReminders(),
                    _toggleExpert(),
                    _toggleExpertAndBeginner(),
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

  Widget _editor() => Flexible(
        child: Container(
          width: PAGE_WIDTH,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: VisualEditor(
            controller: _controller!,
            scrollController: _scrollController,
            focusNode: _focusNode,
            config: EditorConfigM(
              markerTypes: getMarkerTypes(),
              onBuildCompleted: _updateMarkerAttachments,
              onScroll: _updateMarkerAttachments,
            ),
          ),
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
      );

  // Row is space in between, therefore we need on the right side an empty container to force the editor on the center.
  Widget _fillerToBalanceRow() => Container(width: 0);

  Widget _row({required List<Widget> children}) => Container(
        margin: EdgeInsets.only(top: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      );

  Widget _toggleReminders() => DefaultButton(
        name: 'Toggle Reminder Markers',
        onPressed: () {
          final visibility =
              !(_controller?.isMarkerTypeVisible('reminder') ?? false);

          _controller?.toggleMarkerByTypeId('reminder', visibility);
        },
      );

  Widget _toggleExpert() => DefaultButton(
        name: 'Toggle Expert Markers',
        padding: EdgeInsets.symmetric(horizontal: 25),
        onPressed: () {
          final visibility =
              !(_controller?.isMarkerTypeVisible('expert') ?? false);

          _controller?.toggleMarkerByTypeId('expert', visibility);
        },
      );

  Widget _toggleExpertAndBeginner() => DefaultButton(
        name: 'Toggle Expert And Beginner Markers',
        onPressed: () {
          final expertVisibility =
              !(_controller?.isMarkerTypeVisible('expert') ?? false);
          final beginnerVisibility =
              !(_controller?.isMarkerTypeVisible('beginner') ?? false);

          _controller?.toggleMarkerByTypeId('expert', expertVisibility);
          _controller?.toggleMarkerByTypeId('beginner', beginnerVisibility);
        },
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

  Future<void> _loadDocumentAndInitController() async {
    final deltaJson = await rootBundle.loadString(
      'lib/markers/assets/hide-markers.json',
    );
    final document = DeltaDocM.fromJson(jsonDecode(deltaJson));

    setState(() {
      _controller = EditorController(
        document: document,
      );
    });
  }

  List<MarkerTypeM> getMarkerTypes() => [
        MarkerTypeM(
          id: 'expert',
          name: 'Expert',
          color: Colors.amber.withOpacity(0.2),
        ),
        MarkerTypeM(
          id: 'beginner',
          name: 'Beginner',
          color: Colors.blue.withOpacity(0.2),
        ),
        MarkerTypeM(
          id: 'reminder',
          name: 'Reminder',
          color: Colors.cyan.withOpacity(0.2),
        ),
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
