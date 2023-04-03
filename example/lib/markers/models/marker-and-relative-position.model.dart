import 'package:flutter/cupertino.dart';
import 'package:visual_editor/markers/models/marker.model.dart';

// When we use markers in more than one editor we want to keep all of them synchronized.
// Every marker will have a local position (position in its editor) and a relative position
// which is the position of the editor in the page. Combining relative position with local position
// will make markers to be synchronous.
@immutable
class MarkerAndRelPos {
  final MarkerM marker;

  // Used only when we have multiple editors in a single page
  // Represents the total height above the editor which contains the marker
  final double relativePosition;

  const MarkerAndRelPos({
    required this.marker,
    this.relativePosition = 0,
  });
}
