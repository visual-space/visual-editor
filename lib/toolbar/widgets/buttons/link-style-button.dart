import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../../../blocks/services/link.utils.dart';
import '../../../controller/services/controller.dart';
import '../../../documents/models/attribute.dart';
import '../../../shared/models/quill-dialog-theme.model.dart';
import '../../../shared/models/quill-icon-theme.model.dart';
import '../../../shared/translations/toolbar.i18n.dart';
import '../dialogs/link-style-dialog.dart';
import '../toolbar.dart';

class LinkStyleButton extends StatefulWidget {
  final QuillController controller;
  final IconData? icon;
  final double iconSize;
  final QuillIconThemeM? iconTheme;
  final QuillDialogThemeM? dialogTheme;

  const LinkStyleButton({
    required this.controller,
    this.iconSize = kDefaultIconSize,
    this.icon,
    this.iconTheme,
    this.dialogTheme,
    Key? key,
  }) : super(key: key);

  @override
  _LinkStyleButtonState createState() => _LinkStyleButtonState();
}

class _LinkStyleButtonState extends State<LinkStyleButton> {
  void _didChangeSelection() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_didChangeSelection);
  }

  @override
  void didUpdateWidget(covariant LinkStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeSelection);
      widget.controller.addListener(_didChangeSelection);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_didChangeSelection);
  }

  final GlobalKey _toolTipKey = GlobalKey();

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
          size: widget.iconSize * kIconButtonFactor,
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
        .attributes[Attribute.link.key]
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
      LinkAttribute(link),
    );
  }
}
