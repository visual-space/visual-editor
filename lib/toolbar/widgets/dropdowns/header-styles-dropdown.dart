import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/attributes/attributes-aliases.model.dart';
import '../../../document/models/attributes/attributes.model.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/state/editor-state-receiver.dart';
import '../../../shared/state/editor.state.dart';
import '../../../shared/widgets/editor-dropdown.dart';
import '../../../styles/services/styles.service.dart';
import '../../models/dropdown-option.model.dart';

// Controls the header style of the currently selected text.
// ignore: must_be_immutable
class HeaderStylesDropdown extends StatelessWidget
    implements EditorStateReceiver {
  late final StylesService _stylesService;

  final Map<String, int> headerStyles;
  final double iconSize;
  final EditorIconThemeM? iconTheme;
  final EditorController controller;
  int initialHeaderStyleValue;
  late List<DropDownOptionM<int>> options;
  late EditorState _state;

  HeaderStylesDropdown({
    required this.headerStyles,
    required this.controller,
    required this.initialHeaderStyleValue,
    this.iconSize = 40,
    this.iconTheme,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
    _stylesService = StylesService(_state);

    options = _mapStylesToDropdownOptions(headerStyles);
  }

  @override
  void cacheStateStore(EditorState state) {
    _state = state;
  }

  @override
  Widget build(BuildContext context) => EditorDropdown<int>(
        iconTheme: iconTheme,
        iconSize: iconSize,
        attribute: AttributesM.header,
        controller: controller,
        options: options,
        initialValue: _getInitialHeaderStyle(),
        onSelected: (style) => _stylesService.formatSelection(
          _getHeaderAttributeByStyle(style.value),
        ),
      );

  List<DropDownOptionM<int>> _getInitialHeaderStyle() {
    return [
      options.firstWhere(
        (option) => option.value == initialHeaderStyleValue,
      ),
    ];
  }

  List<DropDownOptionM<int>> _mapStylesToDropdownOptions(
    Map<String, int> headerStyles,
  ) =>
      headerStyles.entries
          .map(
            (style) => DropDownOptionM(
              name: style.key,
              value: style.value,
            ),
          )
          .toList();

  AttributeM _getHeaderAttributeByStyle(int size) {
    if (size == 1) {
      return AttributesAliasesM.h1;
    }
    if (size == 2) {
      return AttributesAliasesM.h2;
    }
    if (size == 3) {
      return AttributesAliasesM.h3;
    }

    // Normal text
    return AttributesM.header;
  }
}
