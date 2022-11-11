import 'dart:async';

import 'package:flutter/material.dart';
import 'package:visual_editor/headings/models/heading.model.dart';

// Renders a column with all headings existent in the document 
// Headings are rendered in the same order as they are found in the doc.
class HeadingsPanel extends StatefulWidget {
  final StreamController<List<HeadingM>> headings$;
  final ScrollController? scrollController;

  HeadingsPanel({
    required this.headings$,
    this.scrollController,
  });

  @override
  State<HeadingsPanel> createState() => _HeadingsPanelState();
}

class _HeadingsPanelState extends State<HeadingsPanel> {
  List<HeadingM> _headings = [];
  late StreamSubscription _headingsListener;

  @override
  void initState() {
    _subscribeToHeadings();
    super.initState();
  }

  @override
  void dispose() {
    _headingsListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._headingsText(),
        ],
      ),
    );
  }

  List<Widget> _headingsText() => _headings.map((heading) {
        return InkWell(
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              heading.text ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          onTap: () => _scrollToTheHeadingPosition(heading),
        );
      }).toList();

  void _scrollToTheHeadingPosition(HeadingM heading) {
    final headingPosition = heading.docRelPosition?.dy ?? 0;

    widget.scrollController?.animateTo(
      headingPosition,
      duration: Duration(milliseconds: 300),
      curve: Curves.linear,
    );
  }

  void _subscribeToHeadings() {
    _headingsListener = widget.headings$.stream.listen(
      (headings) => setState(() {
        _headings = headings;
      }),
    );
  }
}
