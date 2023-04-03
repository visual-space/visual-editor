import 'dart:async';

import 'package:flutter/material.dart';
import 'package:visual_editor/markers/models/marker.model.dart';

import '../../markers/models/marker-and-relative-position.model.dart';
import '../../markers/models/markers-attachments-position.dart';

// Handles all the logic needed to synchronize marker-attachments in a page that uses more than an editor
// For every marker we will add its editor relative position (the position related to the whole page) which
// will be used to compute the final position in the page.
// The relative position is calculated using keys that are assigned to editors or other widgets (if they are).
// If the first editor has nothing above them (is the first child of the page) its relative position will be 0.
class MarkerAttachmentsController {
  // (!) This stream is extremely important for maintaining the page performance when updating the attachments positions.
  // The _updateMarkerAttachments() method will be called many times per second when scrolling.
  // Therefore we want to avoid at all costs to setState() in the parent.
  // We will update only the MarkersAttachmentsSidebar via the stream.
  // By using this trick we can prevent Flutter from running expensive page updates.
  // We will target our updates only on the area that renders the attachments (far better performance).
  final markers$ = StreamController<MarkersAttachmentsPos>.broadcast();
  final List<MarkerAndRelPos> _allMarkers = [];

  void cacheMarkersAndRelPos({
    required List<MarkerM?> markers,
    required double relPos,
  }) {
    markers.forEach((marker) {
      if (marker != null) {
        _allMarkers.add(
          MarkerAndRelPos(
            marker: marker,
            relativePosition: relPos,
          ),
        );
      }
    });
  }

  // From here on it's up to the client developer to decide how to draw the attachments.
  // Once you have the build and scroll updates + the pixel coordinates, you can do whatever you want.
  // (!) Inspect the coordinates to draw only the markers that are still visible in the viewport.
  // (!) This method will be invoked many times by the scroll callback.
  // (!) Avoid heavy computations here, otherwise your page might slow down.
  // (!) Avoid setState() on the parent page, setState in a smallest possible widget to minimise the update cost.
  void updateMarkerAttachments(ScrollController scrollController) {
    markers$.sink.add(
      MarkersAttachmentsPos(
        markers: _allMarkers,
        scrollOffset: scrollController.offset,
      ),
    );
  }
}
