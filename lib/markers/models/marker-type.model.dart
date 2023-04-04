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
// Markers types can be arbitrary hidden at any time.
@immutable
class MarkerTypeM {
  final String id;
  final String name;
  final Color color;
  final Color hoverColor;
  final bool isHighlightVisible;
  final bool isTextVisible;
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
    this.isHighlightVisible = true,
    this.isTextVisible = true,
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
        'isHighlightVisible : $isHighlightVisible,'
        'isTextVisible : $isTextVisible,'
        'color: $color, '
        'hoverColor: $hoverColor,'
        ')';
  }

  MarkerTypeM copyWith({
    String? id,
    String? name,
    Color? color,
    Color? hoverColor,
    bool? isHighlightVisible,
    bool? isTextVisible,
    Function(MarkerM marker)? onSingleTapUp,
    Function(MarkerM marker)? onEnter,
    Function(MarkerM marker)? onHover,
    Function(MarkerM marker)? onExit,
  }) =>
      MarkerTypeM(
        id: id ?? this.id,
        name: name ?? this.id,
        color: color ?? this.color,
        hoverColor: hoverColor ?? this.hoverColor,
        isHighlightVisible: isHighlightVisible ?? this.isHighlightVisible,
        isTextVisible: isTextVisible ?? this.isTextVisible,
        onSingleTapUp: onSingleTapUp ?? this.onSingleTapUp,
        onEnter: onEnter ?? this.onEnter,
        onExit: onExit ?? this.onExit,
        onHover: onHover ?? this.onHover,
      );
}
