import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../documents/models/attributes/attributes.model.dart';
import '../../../documents/services/attribute.utils.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/widgets/editor-dropdown.dart';
import '../../models/dropdown-option.model.dart';

// Controls the size of the currently selected text
// ignore: must_be_immutable
class SizesDropdown extends StatelessWidget {
  final Map<String, int> fontSizes;
  final double iconSize;
  final EditorIconThemeM? iconTheme;
  final double toolbarIconSize;
  final EditorController controller;
  int initialFontSizeValue;
  late List<DropDownOptionM<int>> options;

  SizesDropdown({
    required this.fontSizes,
    required this.toolbarIconSize,
    required this.controller,
    required this.initialFontSizeValue,
    this.iconSize = 40,
    this.iconTheme,
    Key? key,
  }) : super(key: key) {
    options = _mapSizesToDropdownOptions(fontSizes);
  }

  @override
  Widget build(BuildContext context) {
    return EditorDropdown<int>(
      iconTheme: iconTheme,
      iconSize: toolbarIconSize,
      attribute: AttributesM.size,
      controller: controller,
      options: options,
      initialValue: _getInitialSize(),
      onSelected: _selectSize,
    );
  }

  List<DropDownOptionM<int>> _getInitialSize() {
    return [
      initialFontSizeValue <= fontSizes.length - 1
          ? options.firstWhere((option) => option.value == initialFontSizeValue)
          : options.firstWhere((option) => option.value == 11),
    ];
  }

  List<DropDownOptionM<int>> _mapSizesToDropdownOptions(
    Map<String, int> fontSizes,
  ) =>
      fontSizes.entries
          .map(
            (e) => DropDownOptionM(
              name: e.key,
              value: e.value,
            ),
          )
          .toList();

  void _selectSize(DropDownOptionM<int> newSize) {
    // Fail safe
    if (newSize.value <= 0) {
      return;
    }

    // Default text size removes the attribute from the text.
    if (newSize.value == 11) {
      controller.formatSelection(
        AttributeUtils.fromKeyValue('size', null),
      );

      // Apply new size
    } else {
      controller.formatSelection(
        AttributeUtils.fromKeyValue('size', newSize.value),
      );
    }
  }
}
