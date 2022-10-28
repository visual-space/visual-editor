import 'dart:async';

import 'package:flutter/material.dart';
import 'package:visual_editor/controller/controllers/editor-controller.dart';
import 'package:visual_editor/markers/models/marker.model.dart';

import '../models/markers-and-scroll-offset.model.dart';

// Delete all markers with the same id from the document.
// Displayed only when a user taps on a marker.
// Tapping elsewhere on the document will hide the delete button.
// Only one delete button is displayed at a time.
class DeleteMarkerSidebar extends StatefulWidget {
  final EditorController controller;
  final StreamController<MarkersAndScrollOffset> marker$;
  final void Function()? onTap;

  DeleteMarkerSidebar({
    required this.marker$,
    required this.controller,
    this.onTap,
  });

  @override
  State<DeleteMarkerSidebar> createState() => _DeleteMarkerSidebarState();
}

class _DeleteMarkerSidebarState extends State<DeleteMarkerSidebar> {
  var _scrollOffset = 0.0;
  late StreamSubscription _markerListener;
  var _marker = MarkerM(id: '', type: '');

  @override
  void initState() {
    _subscribeToMarker();
    super.initState();
  }

  @override
  void dispose() {
    _markerListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      child: Stack(
        children: [
          _deleteButton(),
        ],
      ),
    );
  }

  Widget _deleteButton() => Positioned(
        top: _getMarkerPosition(),
        left: 10,
        child: InkWell(
          child: Icon(
            Icons.close,
            size: 24,
          ),
          onTap: () {
            if (widget.onTap != null) widget.onTap!();
            widget.controller.deleteMarkerById(_marker.id);
          },
        ),
      );

  double _getMarkerPosition() {
    final rectangle = _marker.rectangles?[0];

    return (_marker.docRelPosition?.dy ?? 0) +
        (rectangle?.top ?? 0) -
        _scrollOffset;
  }

  // Update the position of the marker every time when tha page is scrolled.
  // In this way we maintain the performance for the main page doing a setState() on a smaller component.
  // Because we send only one marker we always take the first value from the list
  // (it is more a fail safe and a way to reuse the same model)
  void _subscribeToMarker() {
    _markerListener = widget.marker$.stream.listen(
      (marker) => setState(() {
        _marker = marker.markers.first;
        _scrollOffset = marker.scrollOffset;
      }),
    );
  }
}
