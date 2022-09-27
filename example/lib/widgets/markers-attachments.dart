import 'dart:async';

import 'package:flutter/material.dart';
import 'package:visual_editor/markers/models/marker.model.dart';

import '../models/markers-and-scroll-offset.model.dart';

// Marker attachments are widgets that are synced to mathc the same position on screen as the markers.
// Notice we use a stream to pass the updates instead of using setState on the parent widget which contains the editor.
// By using the stream we avoid heavy re-renders of the editor and we maintain maximum performance.
class MarkersAttachments extends StatefulWidget {
  final StreamController<MarkersAndScrollOffset> markers$;

  MarkersAttachments({
    required this.markers$,
  });

  @override
  State<MarkersAttachments> createState() => _MarkersAttachmentsState();
}

class _MarkersAttachmentsState extends State<MarkersAttachments> {
  List<MarkerM> _markers = [];
  var _scrollOffset = 0.0;
  final _topBarOffset = 60.0;
  late StreamSubscription _markersListener;

  @override
  void initState() {
    _subscribeToMarkers();
    super.initState();
  }

  @override
  void dispose() {
    _markersListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      child: Stack(
        children: [..._attachments()],
      ),
    );
  }

  // (!) AAttachments that exit the viewport should no longer be rendered.
  // For the sake of simplicity of example we don't do this performance check here.
  // Additional logic for collision detection could be implemented as well.
  List<Widget> _attachments() => _markers.map((marker) {
        final rectangle = marker.rectangles?[0];
        return Positioned(
          top: _getMarkerPosition(marker, rectangle),
          left: 10,
          child: Icon(
            _getAttachmentIcon(marker.type),
            color: _getColor(marker.type),
            size: 24,
            semanticLabel: 'Favourite',
          ),
        );
      }).toList();

  IconData _getAttachmentIcon(String type) {
    switch (type) {
      case 'expert':
        return Icons.verified;
      case 'beginner':
        return Icons.school;
      case 'reminder':
        return Icons.alarm;
      default:
        throw Icons.error;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'expert':
        return Colors.amber;
      case 'beginner':
        return Colors.lightBlueAccent;
      case 'reminder':
        return Colors.lightGreen;
      default:
        throw Icons.error;
    }
  }

  double _getMarkerPosition(MarkerM marker, TextBox? rectangle) =>
      (marker.docRelPosition?.dy ?? 0) + (rectangle?.top ?? 0) - _scrollOffset - _topBarOffset;

  void _subscribeToMarkers() {
    _markersListener = widget.markers$.stream.listen(
      (markers) => setState(() {
        _markers = markers.markers;
        _scrollOffset = markers.scrollOffset;
      }),
    );
  }
}
