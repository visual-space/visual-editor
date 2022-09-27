import 'package:flutter/cupertino.dart';
import 'package:visual_editor/markers/models/marker.model.dart';

@immutable
class MarkersAndScrollOffset {
  final List<MarkerM> markers;
  final double scrollOffset;

  const MarkersAndScrollOffset({
    required this.markers,
    required this.scrollOffset,
  });
}
