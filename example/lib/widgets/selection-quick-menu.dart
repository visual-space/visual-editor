import 'dart:async';

import 'package:flutter/material.dart';

// Any kind of widget can be attached to markers and highlights when tapping them.
// Notice we use a stream to pass the updates instead of using setState on the parent widget which contains the editor.
// By using the stream we avoid heavy re-renders of the editor and we maintain maximum performance.
class SelectionQuickMenu extends StatefulWidget {
  final Offset offset;
  final StreamController<Offset> offset$;

  SelectionQuickMenu({
    required this.offset,
    required this.offset$,
  });

  @override
  State<SelectionQuickMenu> createState() => _SelectionQuickMenuState();
}

class _SelectionQuickMenuState extends State<SelectionQuickMenu> {
  Offset _offset = Offset.zero;
  late StreamSubscription _markersListener;

  @override
  void initState() {
    _subscribeToPositionOffset();
    super.initState();
  }

  @override
  void dispose() {
    _markersListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned(
        top: _offset.dy,
        left: _offset.dx,
        child: Container(
          color: Colors.black87,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _quickMenuIcon(Icons.verified),
              _quickMenuIcon(Icons.school),
              _quickMenuIcon(Icons.alarm),
            ],
          ),
        ),
      );

  Widget _quickMenuIcon(IconData icon) => Material(
        color: Colors.transparent,
        child: InkWell(
          hoverColor: Colors.lightBlueAccent,
          child: Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          onTap: () {},
        ),
      );

  // (!) If using rxdart we could avoid the init and additional param by using a BehaviourSubject.
  // However we wanted to keep this lib lightweight and avoid adding unnecessary libs.
  // Therefore the init and update are done via 2 params.
  void _subscribeToPositionOffset() {
    // Init
    _offset = widget.offset;

    // Update
    _markersListener = widget.offset$.stream.listen(
      (offset) => setState(() {
        _offset = offset;
      }),
    );
  }
}
