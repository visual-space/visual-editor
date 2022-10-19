import 'dart:async';

import 'package:flutter/material.dart';

import '../../toolbar/models/dropdown-option.model.dart';
import '../../visual-editor.dart';
import '../state/editor-state-receiver.dart';
import '../state/editor.state.dart';

// The dropdown presents users a list of options that can be assigned to the edited attribute in text.
// The dropdown value updates based on the selected text value of the edit attribute.
// An initial value can be defined.
// If `iconOnly` is enable than the dropdown shows only the icon provided in the `icon` input as the trigger.
// Multiple options can be marked as selected.
// The current visual hint for multiselect is improvised (bold text) in order to avoid loading a new library for multiselect.
// This selection style could be improved in the future if needed.
// Considering there are so few places where the dropdown is used and despite the increase in complexity,
// we decided to have one dropdown that can do it all to avoid code duplication.
// Use getOptionsByCustomAttribute in case the custom attribute you defined
// uses as values complex objects instead of primitives.
// ignore: must_be_immutable
class EditorDropdown<T> extends StatefulWidget with EditorStateReceiver {
  final IconData? icon;
  final bool iconOnly; // Only show the icon, hide the selected value text
  final double iconSize;
  final bool multiselect; // Allow multiple values to be selected
  final Color? fillColor;
  final double hoverElevation;
  final double highlightElevation;
  final List<DropDownOptionM<T>> initialValue;
  final List<DropDownOptionM<T>> options;
  final ValueChanged<DropDownOptionM<T>> onSelected;
  final EditorIconThemeM? iconTheme;
  final AttributeM attribute;
  final EditorController controller;
  final double buttonsSpacing;

  // For attributes types that don't store the value as a primitives
  // we need a custom reader method to return the selected options.
  // This code was separated as a callback to maintain the dropdown generic.
  // Ex: the markers are stored as a complex nested structure that defines multiple layers.
  // This structure needs custom code to be read and interpreted by the dropdown
  final List<DropDownOptionM<T>> Function(dynamic)? getOptionsByCustomAttribute;

  // For attributes types that don't story the value as a primitives
  // we have the ability to count the number of layers per option.
  // This code was separated as a callback to maintain the dropdown generic.
  final int Function(
    dynamic,
    DropDownOptionM<T> option,
  )? countAttributeLayersByOption;

  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  @override
  void setState(EditorState state) {
    _state = state;
  }

  EditorDropdown({
    required this.initialValue,
    required this.options,
    required this.attribute,
    required this.controller,
    required this.onSelected,
    this.getOptionsByCustomAttribute,
    this.countAttributeLayersByOption,
    this.buttonsSpacing = 0,
    this.icon,
    this.iconOnly = false,
    this.iconSize = 40,
    this.multiselect = false,
    this.fillColor,
    this.hoverElevation = 1,
    this.highlightElevation = 1,
    this.iconTheme,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
  }

  @override
  _EditorDropdownState<T> createState() => _EditorDropdownState<T>();
}

class _EditorDropdownState<T> extends State<EditorDropdown<T>> {
  List<DropDownOptionM<T>> _selectedOptions = [];
  StreamSubscription? _refreshListener;

  StyleM get _selectionStyle => widget.controller.getSelectionStyle();

  @override
  void initState() {
    super.initState();
    _subscribeToRefreshListener();
    _selectedOptions = [...widget.initialValue];
  }

  @override
  void dispose() {
    _refreshListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _rectangleButton(
        children: [
          if (widget.icon != null) _icon(),
          if (widget.iconOnly != true) _textAndArrow(),
        ],
      );

  @override
  void didUpdateWidget(covariant EditorDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If a new controller was generated by setState() in the parent
    // we need to subscribe to the new state store.
    if (oldWidget.controller != widget.controller) {
      _refreshListener?.cancel();
      widget.controller.setStateInEditorStateReceiver(widget);
      _subscribeToRefreshListener();
    }
  }

  Widget _rectangleButton({required List<Widget> children}) => Material(
        child: InkWell(
          onTap: _displayOptionsMenu,
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(
              height: widget.iconSize * 1.81,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ),
        ),
      );

  Widget _textAndArrow() {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _selectedOptions.map((option) => option.name).join(' '),
          style: TextStyle(
            fontSize: widget.iconSize / 1.15,
            color:
                widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color,
          ),
        ),
        const SizedBox(
          width: 3,
        ),
        Icon(
          Icons.arrow_drop_down,
          size: widget.iconSize / 1.15,
          color: widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color,
        )
      ],
    );
  }

  Widget _icon() {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        right: widget.iconOnly ? 0 : 6,
      ),
      child: Icon(
        widget.icon,
        size: widget.iconSize,
        color: widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color,
      ),
    );
  }

  // === PRIVATE ===

  // When the editor get refreshed by user interactions we read the text selection
  // and based on it we select the value of the dropdown.
  void _subscribeToRefreshListener() {
    _refreshListener = widget._state.refreshEditor.refreshEditor$.listen(
      (_) {
        setState(
          () => _selectedOptions = _getSelectedOptionsFromTextSelection(),
        );
      },
    );
  }

  void _displayOptionsMenu() {
    final popupMenuTheme = PopupMenuTheme.of(context);
    final position = _getMenuPosition();

    showMenu<DropDownOptionM<T>>(
      context: context,
      elevation: 4,
      initialValue: widget.multiselect ? null : _selectedOptions[0],
      items: [
        for (final option in widget.options)
          PopupMenuItem<DropDownOptionM<T>>(
            key: ValueKey(option),
            value: option,
            child: Row(
              children: [
                _optionName(option),
                if (widget.countAttributeLayersByOption != null)
                  _optionCounter(option)
              ],
            ),
          ),
      ],
      position: position,
      shape: popupMenuTheme.shape,
      color: popupMenuTheme.color,
    ).then(_selectOption);
  }

  // Renders a counter indicator (the behavior is provided by the parent dropdown component, ex: markers dropdown)
  // TODO Consider upgrading to an even more generic solution.
  //  Dropdown options could display any trailing content, not just counters.
  Widget _optionCounter(DropDownOptionM<T> option) {
    final count = _countMarkers(option);

    return count > 0
        ? Text(
            '(${_countMarkers(option)})',
            style: TextStyle(
              fontSize: 11,
            ),
          )
        : SizedBox.shrink();
  }

  Widget _optionName(DropDownOptionM<T> option) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(
          option.name,
          style: TextStyle(
            fontWeight: _isSelected(option) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      );

  RelativeRect _getMenuPosition() {
    final button = context.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context)!.context.findRenderObject() as RenderBox;

    return RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(
          Offset.zero,
          ancestor: overlay,
        ),
        button.localToGlobal(
          button.size.bottomLeft(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );
  }

  // Retrieves the value of the edited attribute from the selected text.
  List<DropDownOptionM<T>> _getSelectedOptionsFromTextSelection() {
    final attribute = _selectionStyle.attributes[widget.attribute.key];
    var selectedOptions = <DropDownOptionM<T>>[];

    // Get the attribute value
    if (attribute != null) {
      // Custom Value
      // Custom implementations of the dropdown can provide a callback for reading the custom data of an attribute
      if (widget.getOptionsByCustomAttribute != null) {
        selectedOptions = widget.getOptionsByCustomAttribute!(attribute.value);
      } else {
        // Primitive Value
        selectedOptions = widget.options
            .where((option) => option.value == attribute.value)
            .toList();
      }

      // Default value.
    } else {
      selectedOptions = [...widget.initialValue];
    }

    return selectedOptions;
  }

  FutureOr<Null> _selectOption(DropDownOptionM<T>? newValue) {

    // Fail safe
    if (!mounted || newValue == null) {
      return null;
    }

    setState(() {
      if (widget.multiselect) {
        _selectMultipleOptions(newValue);
      } else {
        _selectSingleOption(newValue);
      }

      widget.onSelected(newValue);
    });
  }

  void _selectSingleOption(DropDownOptionM<T>? newValue) {
    _selectedOptions = [
      if (newValue != null) newValue,
    ];
  }

  void _selectMultipleOptions(DropDownOptionM<T>? newValue) {
    if (_selectedOptions.contains(newValue)) {
      _selectedOptions.remove(newValue);
    } else {
      _selectedOptions.add(newValue!);
    }
  }

  // When selecting text we want to see if any of the options is already selected
  bool _isSelected(DropDownOptionM<T> option) => _selectedOptions.any(
        (_option) => _option.value == option.value,
      );

  // When selecting text we want to see how many layers of the same marker type are present.
  // It is possible and allowed to enter multiple overlapping markers.
  int _countMarkers(DropDownOptionM<T> option) {
    final attribute = _selectionStyle.attributes[widget.attribute.key];

    // Get the attribute value
    if (attribute != null) {
      // Custom Value
      if (widget.countAttributeLayersByOption != null) {
        return widget.countAttributeLayersByOption!(
          attribute.value,
          option,
        );
      }
    }

    return 0;
  }
}
