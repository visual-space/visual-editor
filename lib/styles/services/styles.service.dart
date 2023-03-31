import 'package:flutter/cupertino.dart';

import '../../document/models/attributes/attributes-aliases.model.dart';
import '../../document/models/attributes/attributes.model.dart';
import '../../document/models/attributes/paste-style.model.dart';
import '../../document/models/attributes/styling-attributes.dart';
import '../../document/models/history/change-source.enum.dart';
import '../../document/services/delta.utils.dart';
import '../../document/services/nodes/attribute.utils.dart';
import '../../document/services/nodes/styles.utils.dart';
import '../../editor/services/run-build.service.dart';
import '../../selection/services/selection.service.dart';
import '../../shared/state/editor.state.dart';
import '../../toolbar/models/font-sizes.const.dart';
import '../../toolbar/services/toolbar.service.dart';
import '../../visual-editor.dart';

final _stylesUtils = StylesUtils();

// Adds style modifications to the document model.
class StylesService {
  late final RunBuildService _runBuildService;
  late final SelectionService _selectionService;
  late final ToolbarService _toolbarService;
  final _du = DeltaUtils();

  final EditorState state;

  StylesService(this.state) {
    _runBuildService = RunBuildService(state);
    _selectionService = SelectionService(state);
    _toolbarService = ToolbarService(state);
  }

  // === FORMAT ===

  // Add multiple styles at once on the selected text
  void formatSelectedTextByStyle(int index, int len, StyleM style) {
    style.attributes.forEach((key, attr) {
      formatTextRange(index, len, attr);
    });
  }

  // Formats the text by adding a new attribute to the selected text.
  // Based on the executed change, we reset the text selection range.
  // Ex: deleting text will decrease the text selection.
  void formatTextRange(
    int index,
    int len,
    AttributeM? attribute,
  ) {
    if (len == 0 &&
        attribute!.isInline &&
        attribute.key != AttributesM.link.key) {
      // Add the attribute to our toggledStyle.
      // It will be used later upon insertion.
      state.styles.updateToggledStyle(attribute);
    }

    final change = state.refs.documentController.format(index, len, attribute);
    final selection = state.selection.selection;

    // Transform selection against the composed change and give priority to the change.
    // This is needed in cases when format operation actually inserts data into the document (e.g. embeds).
    final adjustedSelection = selection.copyWith(
      baseOffset: _du.transformPosition(change, selection.baseOffset),
      extentOffset: _du.transformPosition(change, selection.extentOffset),
    );

    final sameSelection = selection == adjustedSelection;

    if (!sameSelection) {
      _selectionService.cacheSelection(adjustedSelection, ChangeSource.LOCAL);
    }

    // Update Layout
    _runBuildService.runBuild();

    if (!sameSelection) {
      _selectionService.callOnSelectionChanged();
    }
  }

  // Applies an attribute to a selection of text
  void formatSelection(AttributeM? attribute) {
    final selection = state.selection.selection;

    // Styling is disabled for selection that contains code blocks and inline code at this point.
    // (!) Must be added here in order to prevent applying style when using hotkeys too (e.g. Ctrl + B = applies bold attr).
    final isSelectionCode =
        getSelectionStyle().attributes.containsKey('code') ||
            getSelectionStyle().attributes.containsKey('code-block');

    // We must check that the attr applied is code or inline code in order to enable the
    // clear format button.
    final isAttrCode =
        attribute?.key == 'code' || attribute?.key == 'code-block';

    // Don't apply attr that is not code to code selection
    if (isSelectionCode && !isAttrCode) {
      return;
    }

    // Applying code attr over selection (that is not code), without changing selection,
    // buttons color remains enabled, so we must disable and refresh the editor.
    //
    // Using the clear format button (without changing selection) which returns
    // the same attr as code we must also check that the selection is not code
    // in order to make it work properly and set buttons color to enable.
    if (isAttrCode && !isSelectionCode) {
      _selectionService.disableButtonsInCodeSelectionAndRunBuild();
    } else {
      _selectionService.enableButtonsInCodeSelectionAndRunBuild();
    }

    formatTextRange(
      selection.start,
      selection.end - selection.start,
      attribute,
    );
  }

  // === GET STYLES ===

  // Only attributes applied to all characters within this range are included in the result.
  StyleM getSelectionStyle() {
    final selection = state.selection.selection;
    final index = selection.start;
    final length = selection.end - selection.start;

    var style = state.refs.documentController.collectStyle(index, length);
    style = _stylesUtils.mergeAll(style, state.styles.toggledStyle);

    return style;
  }

  // Returns all styles for each node within selection
  List<PasteStyleM> getAllIndividualSelectionStyles() {
    final selection = state.selection.selection;
    final styles = state.refs.documentController.collectAllIndividualStyles(
      selection.start,
      selection.end - selection.start,
    );

    return styles;
  }

  // Returns all styles for any character within the specified text range.
  List<StyleM> getAllSelectionStyles() {
    final selection = state.selection.selection;
    final styles = state.refs.documentController.collectAllStyles(
      selection.start,
      selection.end - selection.start,
    )..add(state.styles.toggledStyle);

    return styles;
  }

  // Checks if selection contains a checklist attribute or not.
  bool hasSelectionChecklistAttr() {
    final attrs = getSelectionStyle().attributes;
    var attribute =
        _toolbarService.getToolbarButtonToggler()[AttributesM.list.key];

    if (attribute == null) {
      attribute = attrs[AttributesM.list.key];
    } else {
      // Checkbox tapping causes controller.selection to go to offset 0
      _toolbarService.getToolbarButtonToggler().remove(AttributesM.list.key);
    }

    if (attribute == null) {
      return false;
    }

    return attribute.value == AttributesAliasesM.unchecked.value ||
        attribute.value == AttributesAliasesM.checked.value;
  }

  // === TOGGLE STYLE ===

  // Returns a boolean to indicate if a text style attribute is enabled or not.
  // List attribute is exempted from this logic.
  bool isAttributeToggledInSelection(AttributeM attribute) {
    final attrs = getSelectionStyle().attributes;

    if (attribute.key == AttributesM.list.key) {
      final targetAttribute = attrs[attribute.key];

      if (targetAttribute == null) {
        return false;
      }

      return targetAttribute.value == attribute.value;
    }

    return attrs.containsKey(attribute.key);
  }

  // Toggles on/off the specified attribute in the current selection
  void toggleAttributeInSelection(AttributeM attribute) {
    final isToggled = isAttributeToggledInSelection(attribute);

    formatSelection(
      isToggled ? AttributeUtils.clone(attribute, null) : attribute,
    );
  }

  void clearSelectionFormatting() {
    final attrs = <AttributeM>{};
    final styles = getAllSelectionStyles();

    for (final style in styles) {
      for (final attr in style.attributes.values) {
        attrs.add(attr);
      }
    }

    for (final attr in attrs) {
      formatSelection(
        AttributeUtils.clone(attr, null),
      );
    }
  }

  // === FONT SIZE ===

  void updateSelectionFontSize(int size) {
    // Fail safe
    if (size <= 0) {
      return;
    }

    // Default text size removes the attribute from the text.
    if (size == INITIAL_FONT_SIZE) {
      formatSelection(
        AttributeUtils.fromKeyValue('size', null),
      );

      // Apply new size
    } else {
      formatSelection(
        AttributeUtils.fromKeyValue('size', size),
      );
    }
  }

  // === COLORS ===

  bool getIsToggledColor(Map<String, AttributeM> attrs) {
    return attrs.containsKey(AttributesM.color.key);
  }

  bool getIsToggledBackground(Map<String, AttributeM> attrs) {
    return attrs.containsKey(AttributesM.background.key);
  }

  // Changes the color of the text (text color or background color)
  void changeSelectionColor(Color color, bool isBgr) {
    var hex = color.value.toRadixString(16);

    if (hex.startsWith('ff')) {
      hex = hex.substring(2);
    }

    hex = '#$hex';
    final attribute = isBgr ? BackgroundAttributeM(hex) : ColorAttributeM(hex);

    formatSelection(attribute);
  }

  // === INDENTATION ===

  void indentSelection(bool isIncrease) {
    final indent = getSelectionStyle().attributes[AttributesM.indent.key];

    // No Styling
    if (indent == null) {
      if (isIncrease) {
        formatSelection(AttributesAliasesM.indentL1);
      }
      return;
    }

    // Prevent decrease bellow 1
    if (indent.value == 1 && !isIncrease) {
      formatSelection(
        AttributeUtils.clone(AttributesAliasesM.indentL1, null),
      );
      return;
    }

    // Increase
    if (isIncrease) {
      formatSelection(
        AttributeUtils.getIndentLevel(indent.value + 1),
      );
      return;
    }

    // Decrease
    formatSelection(
      AttributeUtils.getIndentLevel(indent.value - 1),
    );
  }
}
