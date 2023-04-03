import 'dart:async';

import 'package:flutter/material.dart';

import '../models/marker-and-relative-position.model.dart';
import '../models/markers-attachments-position.dart';

// Marker attachments are widgets that are synced to match the same position on screen as the markers.
// Notice we use a stream to pass the updates instead of using setState on the parent widget which contains the editor.
// By using the stream we avoid heavy re-renders of the editor and we maintain maximum performance.
class MarkersAttachments extends StatefulWidget {
  final StreamController<MarkersAttachmentsPos> markers$;

  MarkersAttachments({
    required this.markers$,
  });

  @override
  State<MarkersAttachments> createState() => _MarkersAttachmentsState();
}

class _MarkersAttachmentsState extends State<MarkersAttachments> {
  List<MarkerAndRelPos> _markers = [];
  var _scrollOffset = 0.0;
  late StreamSubscription _markers$L;

  @override
  void initState() {
    _subscribeToMarkers();
    super.initState();
  }

  @override
  void dispose() {
    _markers$L.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _stack(
        children: [
          for (final marker in _markers)
            _attachment(
              marker: marker,
            ),
        ],
      );

  Widget _stack({required List<Widget> children}) => Container(
        width: 40,
        child: Stack(
          children: children,
        ),
      );

  // (!) Attachments that exit the viewport should no longer be rendered.
  // For the sake of simplicity of example we don't do this performance check here.
  // Additional logic for collision detection could be implemented as well.
  Widget _attachment({required MarkerAndRelPos marker}) {
    final rectangle = marker.marker.rectangles?[0];
    return Positioned(
      top: _getMarkerPosition(marker, rectangle),
      left: 10,
      child: Icon(
        _getAttachmentIcon(marker.marker.type),
        color: _getColor(marker.marker.type),
        size: 24,
        semanticLabel: 'Favourite',
      ),
    );
  }

  // === UTILS ===

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

  double _getMarkerPosition(MarkerAndRelPos marker, TextBox? rectangle) =>
      (marker.marker.docRelPosition?.dy ?? 0) +
      (rectangle?.top ?? 0) +
      marker.relativePosition -
      _scrollOffset;

  void _subscribeToMarkers() {
    _markers$L = widget.markers$.stream.listen(
      (markers) => setState(() {
        _markers = markers.markers;
        _scrollOffset = markers.scrollOffset;
      }),
    );
  }
}
