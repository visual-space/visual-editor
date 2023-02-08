import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../document/models/attributes/attributes.model.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/state/editor-state-receiver.dart';
import '../../../shared/state/editor.state.dart';
import '../../../shared/widgets/editor-dropdown.dart';
import '../../../styles/services/styles.service.dart';
import '../../models/dropdown-option.model.dart';
import '../../models/font-sizes.const.dart';

// Controls the size of the currently selected text
// ignore: must_be_immutable
class SizesDropdown extends StatelessWidget with EditorStateReceiver {
  late final StylesService _stylesService;

  final Map<String, int> fontSizes;
  final double iconSize;
  final EditorIconThemeM? iconTheme;
  final double toolbarIconSize;
  final EditorController controller;
  int initialFontSizeValue;
  late List<DropDownOptionM<int>> options;
  late EditorState _state;

  SizesDropdown({
    required this.fontSizes,
    required this.toolbarIconSize,
    required this.controller,
    required this.initialFontSizeValue,
    this.iconSize = 40,
    this.iconTheme,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
    _stylesService = StylesService(_state);

    options = _mapSizesToDropdownOptions(fontSizes);
  }

  @override
  void cacheStateStore(EditorState state) {
    _state = state;
  }

  @override
  Widget build(BuildContext context) => EditorDropdown<int>(
        iconTheme: iconTheme,
        iconSize: toolbarIconSize,
        attribute: AttributesM.size,
        controller: controller,
        options: options,
        initialValue: _safelyGetInitialFontSize(),
        onSelected: (size) => _stylesService.updateSelectionFontSize(
          size.value,
        ),
      );

  // If the custom initial size exceeds the available font size
  // we default ot the default initial font size
  List<DropDownOptionM<int>> _safelyGetInitialFontSize() {
    return [
      initialFontSizeValue <= fontSizes.length - 1
          ? options.firstWhere((option) => option.value == initialFontSizeValue)
          : options.firstWhere((option) => option.value == INITIAL_FONT_SIZE),
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
}
