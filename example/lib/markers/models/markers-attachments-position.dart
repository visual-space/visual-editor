import 'package:flutter/material.dart';

import 'marker-and-relative-position.model.dart';

// Used to synchronise markers attachments with tha page scroll in order to get the moving effect.
@immutable
class MarkersAttachmentsPos {
  final List<MarkerAndRelPos> markers;

  // If your editor is not scrollable don't provide this parameter or provide 0
  final double scrollOffset;

  const MarkersAttachmentsPos({
    required this.markers,
    this.scrollOffset = 0,
  });
}
