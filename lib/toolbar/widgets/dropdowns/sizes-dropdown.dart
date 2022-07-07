import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../documents/models/attributes/attributes.model.dart';
import '../../../documents/services/attribute.utils.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/widgets/editor-dropdown.dart';

// Controls the size of the currently selected text
// ignore: must_be_immutable
class SizesDropdown extends StatelessWidget {
  final Map<String, int> fontSizes;
  final double iconSize;
  final EditorIconThemeM? iconTheme;
  final double toolbarIconSize;
  final EditorController controller;
  int initialFontSizeValue;

  SizesDropdown({
    required this.fontSizes,
    required this.toolbarIconSize,
    required this.controller,
    required this.initialFontSizeValue,
    this.iconSize = 40,
    this.iconTheme,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => EditorDropdown<int>(
        iconTheme: iconTheme,
        iconSize: toolbarIconSize,
        attribute: AttributesM.size,
        controller: controller,
        options: fontSizes,
        initialValue: initialFontSizeValue <= fontSizes.length - 1
            ? initialFontSizeValue
            : 11,
        onSelected: _selectSize,
      );

  void _selectSize(newSize) {
    if (newSize > 0) {
      controller.formatSelection(
        AttributeUtils.fromKeyValue('size', newSize),
      );
    }

    // Default text size removes the attribute from the text.
    if (newSize == 11) {
      controller.formatSelection(
        AttributeUtils.fromKeyValue('size', null),
      );
    }
  }
}
