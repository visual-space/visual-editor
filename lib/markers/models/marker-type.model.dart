import 'package:flutter/material.dart';

const _DEFAULT_MARKER_COLOR = Color.fromRGBO(0xD4, 0x17, 0xFF, 0.3);
const _HOVERED_MARKER_COLOR = Color.fromRGBO(0x84, 0xB, 0x9E, 0.3);

// Custom markers types can be provided to the EditorController.
// Authors can select from different marker types that have been provided by the app developers.
// The markers are defined in the delta document using the marker attribute
// (unlike highlights which are defined programmatically from the controller).
// Callbacks can be defined to react to hovering and tapping.
@immutable
class MarkerTypeM {
  final String id;
  final String name;
  final Color color;
  final Color hoverColor;
  final Function(MarkerTypeM marker)? onSingleTapUp;
  final Function(MarkerTypeM marker)? onEnter;
  final Function(MarkerTypeM marker)? onHover;
  final Function(MarkerTypeM marker)? onLeave;

  // Can be used to execute arbitrary code when a new marker is added in the document via the markers dropdown.
  // The returning data is used data content for the attribute.
  // Read MarkerM comment for a detailed description of that kind of data can be stored (usually UUIDs).
  final dynamic Function(MarkerTypeM marker)? onAddMarkerViaToolbar;

  const MarkerTypeM({
    required this.id,
    required this.name,
    this.color = _DEFAULT_MARKER_COLOR,
    this.hoverColor = _HOVERED_MARKER_COLOR,
    this.onSingleTapUp,
    this.onEnter,
    this.onHover,
    this.onLeave,
    this.onAddMarkerViaToolbar,
  });
}
