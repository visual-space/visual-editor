import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../widgets/demo-scaffold.dart';
import '../widgets/loading.dart';

// Markers are highlights that are permanently defined in the documents.
// They can be enabled on demand.
class MarkersPage extends StatefulWidget {
  @override
  _MarkersPageState createState() => _MarkersPageState();
}

class _MarkersPageState extends State<MarkersPage> {
  EditorController? _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    _loadDocument();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _scaffold(
        children: _controller != null
            ? [
                _editor(),
                _markersControls(),
                _toolbar(),
              ]
            : [
                Loading(),
              ],
      );

  Widget _scaffold({required List<Widget> children}) => DemoScaffold(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        ),
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
            scrollController: ScrollController(),
            focusNode: _focusNode,
            config: EditorConfigM(
              // Uncomment this param if you want to initialise the editor with the markers turned off.
              // They can later be re-enabled at runtime via the controller.
              markersVisibility: true,
            ),
          ),
        ),
      );

  Widget _markersControls() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            child: Text('Add Marker'),
            onPressed: () {
              _controller?.addMarker('expert');
            },
          ),
          OutlinedButton(
            child: Text('Toggle Markers'),
            onPressed: () {
              final visibility =
                  !(_controller?.getMarkersVisibility() ?? false);
              _controller?.toggleMarkers(visibility);
            },
          ),
        ],
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

  Future<void> _loadDocument() async {
    final result = await rootBundle.loadString('assets/docs/markers.json');
    final document = DocumentM.fromJson(jsonDecode(result));

    setState(() {
      _controller = EditorController(
        document: document,
        markerTypes: [
          MarkerTypeM(
            name: 'Expert',
            id: 'expert',
            color: Colors.amber.withOpacity(0.2),
            onAddMarkerViaToolbar: (_) => 'fake-id-1',
          ),
          MarkerTypeM(
            name: 'Beginner',
            id: 'beginner',
            color: Colors.blue.withOpacity(0.2),
            onAddMarkerViaToolbar: (_) => 'fake-id-2',
          ),
          MarkerTypeM(
            name: 'Reminder',
            id: 'reminder',
            color: Colors.cyan.withOpacity(0.2),
            onAddMarkerViaToolbar: (_) => 'fake-id-3',
          ),
        ],
      );
    });
  }
}
