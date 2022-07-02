import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../../../blocks/services/link.utils.dart';
import '../../../controller/controllers/editor-controller.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/styling-attributes.dart';
import '../../../shared/models/editor-dialog-theme.model.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/state/editor-state-receiver.dart';
import '../../../shared/state/editor.state.dart';
import '../../../shared/translations/toolbar.i18n.dart';
import '../dialogs/link-style-dialog.dart';
import '../toolbar.dart';

// ignore: must_be_immutable
class LinkStyleButton extends StatefulWidget with EditorStateReceiver {
  final EditorController controller;
  final IconData? icon;
  final double iconSize;
  final EditorIconThemeM? iconTheme;
  final EditorDialogThemeM? dialogTheme;

  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  @override
  void setState(EditorState state) {
    _state = state;
  }

  LinkStyleButton({
    required this.controller,
    this.iconSize = defaultIconSize,
    this.icon,
    this.iconTheme,
    this.dialogTheme,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
  }

  @override
  _LinkStyleButtonState createState() => _LinkStyleButtonState();
}

class _LinkStyleButtonState extends State<LinkStyleButton> {
  final GlobalKey _toolTipKey = GlobalKey();
  late final StreamSubscription _updateListener;

  @override
  void initState() {
    super.initState();
    _updateListener = widget._state.refreshEditor.updateEditor$.listen(
      (_) => _didChangeSelection,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _updateListener.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToggled = _getLinkAttributeValue() != null;
    final pressedHandler = () => _openLinkDialog(context);

    return GestureDetector(
      onTap: () async {
        final dynamic tooltip = _toolTipKey.currentState;
        tooltip.ensureTooltipVisible();
        Future.delayed(
          const Duration(
            seconds: 3,
          ),
          tooltip.deactivate,
        );
      },
      child: Tooltip(
        key: _toolTipKey,
        message: 'Please first select some text to transform into a link.'.i18n,
        child: IconBtn(
          highlightElevation: 0,
          hoverElevation: 0,
          size: widget.iconSize * iconButtonFactor,
          icon: Icon(
            widget.icon ?? Icons.link,
            size: widget.iconSize,
            color: isToggled
                ? (widget.iconTheme?.iconSelectedColor ??
                    theme.primaryIconTheme.color)
                : (widget.iconTheme?.iconUnselectedColor ??
                    theme.iconTheme.color),
          ),
          fillColor: isToggled
              ? (widget.iconTheme?.iconSelectedFillColor ??
                  theme.toggleableActiveColor)
              : (widget.iconTheme?.iconUnselectedFillColor ??
                  theme.canvasColor),
          borderRadius: widget.iconTheme?.borderRadius ?? 2,
          onPressed: pressedHandler,
        ),
      ),
    );
  }

  // === PRIVATE ===

  void _didChangeSelection() {
    setState(() {});
  }

  void _openLinkDialog(BuildContext context) {
    showDialog<dynamic>(
      context: context,
      builder: (ctx) {
        final link = _getLinkAttributeValue();
        final index = widget.controller.selection.start;

        var text;
        if (link != null) {
          // text should be the link's corresponding text, not selection
          final leaf =
              widget.controller.document.querySegmentLeafNode(index).item2;
          if (leaf != null) {
            text = leaf.toPlainText();
          }
        }

        final len = widget.controller.selection.end - index;
        text ??= len == 0
            ? ''
            : widget.controller.document.getPlainText(
                index,
                len,
              );
        return LinkStyleDialog(
          dialogTheme: widget.dialogTheme,
          link: link,
          text: text,
        );
      },
    ).then(
      (value) {
        if (value != null) _linkSubmitted(value);
      },
    );
  }

  String? _getLinkAttributeValue() {
    return widget.controller
        .getSelectionStyle()
        .attributes[AttributeM.link.key]
        ?.value;
  }

  void _linkSubmitted(dynamic value) {
    // text.isNotEmpty && link.isNotEmpty
    final String text = (value as Tuple2).item1;
    final String link = value.item2.trim();
    var index = widget.controller.selection.start;
    var length = widget.controller.selection.end - index;

    if (_getLinkAttributeValue() != null) {
      // text should be the link's corresponding text, not selection
      final leaf = widget.controller.document.querySegmentLeafNode(index).item2;
      if (leaf != null) {
        final range = getLinkRange(leaf);
        index = range.start;
        length = range.end - range.start;
      }
    }

    widget.controller.replaceText(
      index,
      length,
      text,
      null,
    );

    widget.controller.formatText(
      index,
      text.length,
      LinkAttributeM(link),
    );
  }
}
