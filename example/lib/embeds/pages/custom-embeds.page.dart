import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../shared/widgets/demo-page-scaffold.dart';
import '../builders/album-embed.builder.dart';
import '../builders/basic-embed.builder.dart';
import '../const/demo-embeds.const.dart';

// Custom embeds can be used to render any random widgets that you need to display inside the delta document.
// Embeds can store additional data to be retrieved such as the album images in a gallery custom embed widget.
// Embeds need custom defined builders (middleware) to be rendered.
// You can either extend the toolbar with custom button, build a custom toolbar from scratch or command the controller to add embeds.
class CustomEmbedsPage extends StatefulWidget {
  const CustomEmbedsPage({Key? key}) : super(key: key);

  @override
  State<CustomEmbedsPage> createState() => _CustomEmbedsPageState();
}

class _CustomEmbedsPageState extends State<CustomEmbedsPage> {
  late EditorController _controller;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    _setupEditorController();
    _loadDocument();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _scaffold(
        children: [
          _editor(),
          _toolbar(
            customButtons: [
              _insertBasicEmbedButton(),
              _insertAlbumEmbedButton(),
            ],
          ),
        ],
      );

  Widget _scaffold({required List<Widget> children}) => DemoPageScaffold(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        ),
      );

  Widget _toolbar({required List<CustomToolbarButtonM> customButtons}) =>
      EditorToolbar.basic(
        controller: _controller,
        customButtons: customButtons,
        showBackgroundColorButton: false,
        showImageButton: false,
        showVideoButton: false,
        showListBullets: false,
        showListCheck: false,
        showCodeBlock: false,
        showIndent: false,
        showListNumbers: false,
        showQuote: false,
        showDividers: false,
        showLink: false,
        showInlineCode: false,
        showClearFormat: false,
      );

  // Insert a basic custom embed in the document
  CustomToolbarButtonM _insertBasicEmbedButton() => CustomToolbarButtonM(
        icon: Icons.add_box,
        onTap: () {
          final index = _controller.selection.baseOffset;
          final length = _controller.selection.extentOffset - index;

          _controller.replace(
            index,
            length,
            EmbedM(BASIC_EMBED_TYPE),
            null,
          );
        },
      );

  // Insert an album custom embed in the document
  CustomToolbarButtonM _insertAlbumEmbedButton() => CustomToolbarButtonM(
        icon: Icons.star,
        onTap: () {
          final index = _controller.selection.baseOffset;
          final length = _controller.selection.extentOffset - index;
          final imageUrls = [
            'https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885__480.jpg',
            'https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885__480.jpg',
            'https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885__480.jpg',
            'https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885__480.jpg',
          ];

          _controller.replace(
            index,
            length,
            EmbedM(ALBUM_EMBED_TYPE, imageUrls),
            null,
          );
        },
      );

  Widget _editor() => Expanded(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
            ),
            child: VisualEditor(
              controller: _controller,
              scrollController: _scrollController,
              focusNode: _focusNode,
              config: EditorConfigM(
                placeholder: 'Enter text',
                customEmbedBuilders: [
                  BasicEmbedBuilder(),
                  AlbumEmbedBuilder(),
                ],
              ),
            ),
          ),
        ),
      );

  // === UTILS ===

  void _setupEditorController() {
    _controller = EditorController(
      document: DeltaDocM.fromJson(
        jsonDecode(LOREM_LIPSUM_DOC_JSON),
      ),
    );
  }

  Future<void> _loadDocument() async {
    final doc = await rootBundle.loadString(
      'lib/embeds/assets/custom-embeds.json',
    );
    final delta = DeltaDocM.fromJson(jsonDecode(doc)).delta;

    _controller.update(
      delta,

      // Prevents the insertion of the caret if the editor is not focused
      ignoreFocus: true,
    );
  }
}
