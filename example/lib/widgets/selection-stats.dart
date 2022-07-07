import 'dart:async';

import 'package:flutter/material.dart';

// A small component for rendering the selection.
// Notice we use a stream to pass the updates instead of using setState on the parent widget which contains the editor.
// By using the stream we avoid heavy re-renders of the editor and we maintain maximum performance.
class SelectionStats extends StatefulWidget {
  final StreamController<TextSelection> selection$;

  SelectionStats({
    required this.selection$,
  });

  @override
  State<SelectionStats> createState() => _SelectionStatsState();
}

class _SelectionStatsState extends State<SelectionStats> {
  TextSelection selection = TextSelection.collapsed(
    offset: 0,
  );
  late StreamSubscription selectionListener;

  @override
  void initState() {
    _subscribeToTextSelection();
    super.initState();
  }

  @override
  void dispose() {
    selectionListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          'Base offset: ${selection.baseOffset} - Extent offset: ${selection.extentOffset}',
          style: TextStyle(
            fontSize: 30,
          ),
        ),
      );

  void _subscribeToTextSelection() {
    selectionListener = widget.selection$.stream.listen(
      (_selection) => setState(() {
        selection = _selection;
      }),
    );
  }
}
