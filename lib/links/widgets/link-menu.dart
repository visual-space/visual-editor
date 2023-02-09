import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controller/controllers/editor-controller.dart';
import '../../doc-tree/services/coordinates.service.dart';
import '../../document/models/attributes/attributes.model.dart';
import '../../document/services/nodes/node.utils.dart';
import '../../editor/services/editor.service.dart';
import '../../selection/services/selection.service.dart';
import '../../shared/state/editor-state-receiver.dart';
import '../../shared/state/editor.state.dart';
import '../../shared/widgets/tooltip-menu.dart';
import '../../styles/services/styles.service.dart';
import '../../toolbar/widgets/dialogs/link-style-dialog.dart';
import '../services/links.service.dart';

// When tapping links this menu opens, displaying the url of the link, 
// and 3 buttons (edit link, remove link from text/url, and copy link to clipboard)
// ignore: must_be_immutable
class LinkMenu extends StatefulWidget with EditorStateReceiver {
  final EditorController controller;
  late EditorState _state;

  LinkMenu({
    required this.controller,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
  }

  @override
  State<LinkMenu> createState() => _LinkMenuState();

  @override
  void cacheStateStore(EditorState state) {
    _state = state;
  }
}

class _LinkMenuState extends State<LinkMenu> {
  late final EditorService _editorService;
  late final SelectionService _selectionService;
  late final StylesService _stylesService;
  late final CoordinatesService _coordinatesService;
  late final LinksService _linksService;

  @override
  void initState() {
    _editorService = EditorService(widget._state);
    _selectionService = SelectionService(widget._state);
    _coordinatesService = CoordinatesService(widget._state);
    _stylesService = StylesService(widget._state);
    _linksService =  LinksService(widget._state);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final offset = _getOffsetForLinkMenu();

    return Positioned(
      top: offset.dy,
      left: offset.dx,
      child: TooltipMenu(
        children: [
          _linkUrl(),
          _removeLinkBtn(),
          _editLinkBtn(),
          _copyLinkToClipboardBtn(),
        ],
      ),
    );
  }

  Widget _removeLinkBtn() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _linksService.removeLink,
          child: Container(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.link_off,
            ),
          ),
        ),
      );

  Widget _editLinkBtn() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openLinkDialog(context),
          child: Container(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.edit,
            ),
          ),
        ),
      );

  // TODO Add functionality after adding the commit (158 I think) responsible for
  // keyboard shortcuts on master, you need the code from there.
  Widget _copyLinkToClipboardBtn() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Container(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.copy,
            ),
          ),
        ),
      );

  Widget _linkUrl() => InkWell(
        onTap: _launchUrl,
        // Add underline on hover
        onHover: (_) {},
        child: Padding(
          padding: EdgeInsets.only(right: 10),
          child: Text(
            _getLinkAttributeValue() ?? 'No Link',
            style: TextStyle(
              color: Colors.blue,
            ),
          ),
        ),
      );

  Future<void> _launchUrl() async {
    await launchUrl(Uri.parse(_getLinkAttributeValue()!));
  }

  String? _getLinkAttributeValue() => _stylesService
      .getSelectionStyle()
      .attributes[AttributesM.link.key]
      ?.value;

  Offset _getOffsetForLinkMenu() {
    // Default value, if not set.
    var offset = Offset.infinite;

    final linkRect = widget._state.selectedLink.selectedLinkRectangles;
    final hasRect = linkRect.isNotEmpty;

    if (hasRect) {
      final firstLinkRectIsNotEmpty = linkRect[0].rectangles.isNotEmpty;

      if (firstLinkRectIsNotEmpty) {
        final isLinkSelected =
            _stylesService.getSelectionStyle().attributes.containsKey('link');

        if (isLinkSelected) {
          // Get positions for offset
          final rectangle = linkRect[0].rectangles[0];
          final lineOffset = linkRect[0].docRelPosition;

          final childAtOffset = _coordinatesService.childAtOffset(lineOffset);
          final docOffset = NodeUtils().getDocumentOffset(
            childAtOffset.container,
          );
          final extentOffset = widget.controller.selection.extentOffset;
          final lineHeight = childAtOffset.preferredLineHeight(
            TextPosition(
              offset: extentOffset - docOffset,
            ),
          );
          final hLeftPoint = rectangle.left;
          const triangleTooltipMargin = 10;

          // Menu Position
          offset = Offset(
            hLeftPoint - triangleTooltipMargin,
            lineOffset.dy + lineHeight + rectangle.top,
          );

          return offset;
        }
      }
    }

    // Fail case
    return offset;
  }

  void _openLinkDialog(BuildContext context) {
    showDialog<dynamic>(
      context: context,
      builder: (ctx) {
        final link = _editorService.getSelectionLinkAttributeValue();
        final selection = _selectionService.selection;
        final index = selection.start;
        var text;

        if (link != null) {
          // Text should be the link's corresponding text, not selection
          final leaf =
              widget._state.refs.documentController.queryNode(index).leaf;

          if (leaf != null) {
            text = leaf.toPlainText();
          }
        }

        final len = selection.end - index;
        text ??= len == 0
            ? ''
            : widget._state.refs.documentController
            .getPlainTextAtRange(index, len);

        return LinkStyleDialog(
          link: link,
          text: text,
        );
      },
    ).then(
          (value) {
        if (value != null) _editorService.addLinkToSelection(value);
      },
    );
  }
}
