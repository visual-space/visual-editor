import 'package:flutter/cupertino.dart';
import 'package:visual_editor/markers/models/marker.model.dart';

@immutable
class MarkersAndScrollOffset {
  final List<MarkerM> markers;

  // If your editor is not scrollable don't provide this parameter or provide 0
  final double scrollOffset;

  const MarkersAndScrollOffset({
    required this.markers,
    this.scrollOffset = 0,
  });
}
