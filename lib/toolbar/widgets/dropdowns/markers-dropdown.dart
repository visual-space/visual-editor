import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../documents/models/attributes/attributes.model.dart';
import '../../../documents/services/attribute.utils.dart';
import '../../../markers/models/markers-type.model.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/widgets/editor-dropdown.dart';

final defaultMarker = MarkersTypeM(
  id: 'marker',
  name: 'Marker',
);

// Applies one of the available marker types.
// ignore: must_be_immutable

class MarkersDropdown extends StatelessWidget {
  final List<MarkersTypeM> markers;
  final double iconSize;
  final EditorIconThemeM? iconTheme;
  final double toolbarIconSize;
  final EditorController controller;

  MarkersDropdown({
    required this.markers,
    required this.toolbarIconSize,
    required this.controller,
    this.iconSize = 40,
    this.iconTheme,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => EditorDropdown<String>(
        iconTheme: iconTheme,
        iconSize: toolbarIconSize,
        attribute: AttributesM.marker,
        controller: controller,
        onSelected: _selectMarker,
        options: {
          defaultMarker.name: defaultMarker.id,
        },
        initialValue: defaultMarker.id,
        width: 100,
      );

  void _selectMarker(newMarker) {
    print('+++ newMarker $newMarker');
    controller.formatSelection(
      AttributeUtils.fromKeyValue('marker', newMarker),
    );
  }
}
