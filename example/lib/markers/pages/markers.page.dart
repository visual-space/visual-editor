import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/shared/widgets/default-button.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../shared/widgets/demo-page-scaffold.dart';
import '../../shared/widgets/loading.dart';

// Markers are highlights that are permanently defined in the document.
// They can be enabled on demand.
class MarkersPage extends StatefulWidget {
  @override
  _MarkersPageState createState() => _MarkersPageState();
}

class _MarkersPageState extends State<MarkersPage> {
  EditorController? _controller;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    _loadDocumentAndInitController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _scaffold(
        children: _controller != null
            ? [
                _editor(),
                _row(
                  children: [
                    _addMarkerButton(),
                    _toggleMarkersButton(),
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
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: VisualEditor(
            controller: _controller!,
            scrollController: _scrollController,
            focusNode: _focusNode,
            config: EditorConfigM(
              markerTypes: _getMarkerTypes(),
              // Uncomment this param if you want to initialise the editor with the markers turned off.
              // They can later be re-enabled at runtime via the controller.
              // markersVisibility: true,
            ),
          ),
        ),
      );

  Widget _row({required List<Widget> children}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children,
      );

  Widget _addMarkerButton() => DefaultButton(
        name: 'Add Marker',
        onPressed: () {
          _controller?.addMarker('expert');
        },
      );

  Widget _toggleMarkersButton() => DefaultButton(
        name: 'Toggle Markers',
        onPressed: () {
          final visibility = !(_controller?.getMarkersVisibility() ?? false);

          _controller?.toggleMarkers(visibility);
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
      'lib/markers/assets/markers.json',
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
          id: 'expert',
          name: 'Expert',
          color: Colors.amber.withOpacity(0.2),
          onAddMarkerViaToolbar: (_) => 'fake-id-1',
          onSingleTapUp: (marker) {
            print('Marker Tapped - ${marker.type}');
          },
        ),
        MarkerTypeM(
          id: 'beginner',
          name: 'Beginner',
          color: Colors.blue.withOpacity(0.2),
          onAddMarkerViaToolbar: (_) => 'fake-id-2',
          onSingleTapUp: (marker) {
            print('Marker Tapped - ${marker.type}');
          },
        ),
        MarkerTypeM(
          id: 'reminder',
          name: 'Reminder',
          color: Colors.cyan.withOpacity(0.2),
          onAddMarkerViaToolbar: (_) => 'fake-id-3',
          onSingleTapUp: (marker) {
            print('Marker Tapped - ${marker.type}');
          },
        ),
      ];
}
