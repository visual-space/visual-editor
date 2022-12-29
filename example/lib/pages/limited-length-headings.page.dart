import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../const/dimensions.const.dart';
import '../controllers/headings-counter.controller.dart';
import '../widgets/characters-counter.smart.dart';
import '../widgets/demo-page-scaffold.dart';
import '../widgets/loading.dart';

// Headers can have a special behavior when they exceed a characters limit.
// For example, anytime a heading exceeds the limit we highlight the extra characters
// and display a counter for them.
class LimitedLengthHeadingsPage extends StatefulWidget {
  @override
  _LimitedLengthHeadingsPageState createState() =>
      _LimitedLengthHeadingsPageState();
}

class _LimitedLengthHeadingsPageState extends State<LimitedLengthHeadingsPage> {
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
  Widget build(BuildContext context) {
    return _scaffold(
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
  }

  Widget _stack({required List<Widget> children}) => Stack(
        children: children,
      );

  Widget _scaffold({required List<Widget> children}) => DemoPageScaffold(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        ),
      );

  Widget _charactersCounters() => CharacterCountersSmart(
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
        config: EditorConfigM(),
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
      'assets/docs/limited-length-headings.json',
    );
    final document = DocumentM.fromJson(jsonDecode(result));
    setState(() {
      _controller = EditorController(
        document: document,
        onBuildComplete: _initHeadingsCounterController,
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
