import 'package:flutter/material.dart';

const _DEFAULT_MARKER_COLOR = Color.fromRGBO(0xD4, 0x17, 0xFF, 0.3);
const _HOVERED_MARKER_COLOR = Color.fromRGBO(0x84, 0xB, 0x9E, 0.3);

// Custom markers types can be provided to the EditorController.
// Authors can select from different marker types that have been provided by the app developers.
// The markers are defined in the delta document using the marker attribute
// (unlike highlights which are defined programmatically from the controller).
// Callbacks can be defined to react to hovering and tapping.
@immutable
class MarkersTypeM {
  final String id;
  final String name;
  final Color color;
  final Color hoverColor;
  final Function(MarkersTypeM marker)? onSingleTapUp;
  final Function(MarkersTypeM marker)? onEnter;
  final Function(MarkersTypeM marker)? onHover;
  final Function(MarkersTypeM marker)? onLeave;

  const MarkersTypeM({
    required this.id,
    required this.name,
    this.color = _DEFAULT_MARKER_COLOR,
    this.hoverColor = _HOVERED_MARKER_COLOR,
    this.onSingleTapUp,
    this.onEnter,
    this.onHover,
    this.onLeave,
  });
}
