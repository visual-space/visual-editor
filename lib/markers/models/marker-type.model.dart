import 'package:flutter/material.dart';

import 'marker.model.dart';

// TODO Move to shared colors
const _DEFAULT_MARKER_COLOR = Color.fromRGBO(0xD4, 0x17, 0xFF, 0.3);
const _HOVERED_MARKER_COLOR = Color.fromRGBO(0x84, 0xB, 0x9E, 0.3);

// TODO Consider adding material icon as config (toolbar dropdown, marker attachments)
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
  final Function(MarkerM marker)? onSingleTapUp;
  final Function(MarkerM marker)? onEnter;
  final Function(MarkerM marker)? onHover;
  final Function(MarkerM marker)? onExit;

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
    this.onExit,
    this.onAddMarkerViaToolbar,
  });

  @override
  String toString() {
    return 'MarkerTypeM('
        'id: $id, '
        'name: $name, '
        'color: $color, '
        'hoverColor: $hoverColor,'
        ')';
  }
}
