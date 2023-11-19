import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../document/models/attributes/attributes.model.dart';
import '../../../markers/const/default-marker-type.const.dart';
import '../../../markers/services/markers.service.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/state/editor-state-receiver.dart';
import '../../../shared/state/editor.state.dart';
import '../../../shared/widgets/editor-dropdown.dart';
import '../../models/dropdown-option.model.dart';

// When the dropdown renders the list we highlight the options selected in the current text selection.
// Most attributes use primitive values such as the sizes dropdown.
// However the markers use a custom data format to store multiple layers in one attribute.
// Therefore we need a custom method to read the attributes values and
// to convert them into selected dropdown options.
// Applies one of the available marker types.
// ignore: must_be_immutable
class MarkersDropdown extends StatelessWidget implements EditorStateReceiver {
  late final MarkersService _markersService;

  final double iconSize;
  final EditorIconThemeM? iconTheme;
  final double toolbarIconSize;
  final EditorController controller;
  final double buttonsSpacing;
  late List<DropDownOptionM<String>> _markersTypes;
  late EditorState _state;

  MarkersDropdown({
    required this.toolbarIconSize,
    required this.controller,
    required this.buttonsSpacing,
    this.iconSize = 40,
    this.iconTheme,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
    _markersService = MarkersService(_state);
    _initMarkersTypes();
  }

  @override
  void cacheStateStore(EditorState state) {
    _state = state;
  }

  @override
  Widget build(BuildContext context) => EditorDropdown<String>(
        iconTheme: iconTheme,
        icon: Icons.read_more,
        iconOnly: true,
        iconSize: toolbarIconSize,
        multiselect: true,
        attribute: AttributesM.markers,
        controller: controller,
        onSelected: _selectMarker,
        buttonsSpacing: buttonsSpacing,
        options: _markersTypes,
        initialValue: [],
        getOptionsByCustomAttribute: _getOptionsByCustomAttribute,
        countAttributeLayersByOption: _countMarkerLayersByOption,
      );

  // Initialises the dropdown options with the markers types as defined in the controller (or uses a default).
  void _initMarkersTypes() {
    final markersTypes = _state.markersTypes.markersTypes;

    // Custom markers types
    if (markersTypes.isNotEmpty) {
      _markersTypes = markersTypes
          .map((type) => DropDownOptionM(
                name: type.name,
                value: type.id,
              ))
          .toList();

      // Default marker type
    } else {
      _markersTypes = [
        DropDownOptionM(
          name: DEFAULT_MARKER_TYPE.name,
          value: DEFAULT_MARKER_TYPE.id,
        ),
      ];
    }
  }

  // When the dropdown renders the list we highlight the options selected in the current text selection.
  // Most attributes use primitive values such as the sizes dropdown.
  // However the markers use a custom data format to store multiple layers in one attribute.
  // Therefore we need a custom method to read the attributes values and
  // to convert them into selected dropdown options.
  List<DropDownOptionM<String>> _getOptionsByCustomAttribute(markers) {
    assert(
      markers.runtimeType.toString() == 'List<MarkerM>',
      'The markers dropdown received the wrong attribute. '
      'Unexpected type ${markers.runtimeType.toString()}',
    );

    if (markers.runtimeType.toString() == 'List<MarkerM>') {
      final matchedTypes = _markersTypes
          .where(
            (markerType) => markers.any(
              (marker) => marker.type == markerType.value,
            ),
          )
          .toList();

      return matchedTypes;
    } else {
      return [];
    }
  }

  // In the case of markers we can have multiple overlapping markers on the same text selection (even of the same type).
  // Therefore we decided to render a counter to indicate how many times a marker layer was already added.
  // Removing the markers can't be easily done with clarity from the dropdown
  // It's not easy to tell with confidence which marker will be removed.
  // Therefore the solution is to integrate in the text content itself the removal controls for markers.
  // In other words the dropdown is used only for adding but not for removing markers.
  int _countMarkerLayersByOption(markers, DropDownOptionM<String> option) {
    assert(
      markers.runtimeType.toString() == 'List<MarkerM>',
      'The markers dropdown received the wrong attribute. '
      'Unexpected type ${markers.runtimeType.toString()}',
    );

    if (markers.runtimeType.toString() == 'List<MarkerM>') {
      final matchedMarkers = markers
          .where(
            (marker) => marker.type == option.value,
          )
          .toList();

      return matchedMarkers.length;
    } else {
      return 0;
    }
  }

  // The logic used to add new markers on top of existing ones or from scratch.
  void _selectMarker(DropDownOptionM<String> markerOption) {
    _markersService.addMarker(markerOption.value);
  }
}
