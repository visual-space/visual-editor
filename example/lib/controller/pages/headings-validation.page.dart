import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../shared/const/dimensions.const.dart';
import '../../shared/widgets/demo-page-scaffold.dart';
import '../../shared/widgets/loading.dart';
import '../controllers/headings-counter.controller.dart';
import '../widgets/characters-counter.dart';

// Headers can have a special behavior when they exceed a characters limit.
// For example, anytime a heading exceeds the limit we highlight the extra characters
// and display a counter for them.
class HeadingsValidationPage extends StatefulWidget {
  @override
  _HeadingsValidationPageState createState() => _HeadingsValidationPageState();
}

class _HeadingsValidationPageState extends State<HeadingsValidationPage> {
  EditorController? _controller;
  final _headingsCounterController = HeadingsCounterController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    _loadDocumentAndInitController();
    _subscribeToPageScrollAndUpdateCounters();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _scaffold(
        children: _controller != null
            ? [
                _whitePage(
                  child: _stack(
                    children: [
                      _editor(),
                      _charactersCounters(),
                    ],
                  ),
                ),
                _toolbar(),
              ]
            : [
                Loading(),
              ],
      );

  Widget _stack({required List<Widget> children}) => Stack(
        children: children,
      );

  Widget _scaffold({required List<Widget> children}) => DemoPageScaffold(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        ),
      );

  Widget _charactersCounters() => CharacterCounters(
        headingsController: _headingsCounterController,
      );

  Widget _whitePage({required Widget child}) => Flexible(
        child: Container(
          width: PAGE_WIDTH,
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(60, 30, 60, 30),
          child: child,
        ),
      );

  Widget _editor() => VisualEditor(
        controller: _controller!,
        scrollController: _scrollController,
        focusNode: _focusNode,
        config: EditorConfigM(
          onBuildCompleted: _initHeadingsCounterController,
        ),
      );

  Widget _toolbar() => Container(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        child: EditorToolbar.basic(
          controller: _controller!,
          showMarkers: true,
          multiRowsDisplay: false,
        ),
      );

  // === UTILS ===

  Future<void> _loadDocumentAndInitController() async {
    final result = await rootBundle.loadString(
      'lib/controller/assets/headings-validation.json',
    );
    final document = DeltaDocM.fromJson(jsonDecode(result));
    setState(() {
      _controller = EditorController(
        document: document,
      );
    });
  }

  void _initHeadingsCounterController() {
    _headingsCounterController.init(
      _controller!,
      _scrollController.offset,
    );
  }

  void _subscribeToPageScrollAndUpdateCounters() {
    _scrollController.addListener(() {
      _headingsCounterController.updateCountersPositions(
        _scrollController.offset,
      );
    });
  }
}
