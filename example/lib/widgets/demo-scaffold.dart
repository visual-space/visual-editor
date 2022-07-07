import 'package:flutter/material.dart';

import 'nav-menu.dart';

// Scaffold used by all pages in the demo app.
// It provides the navigation menu used to navigate between examples.
class DemoScaffold extends StatefulWidget {
  const DemoScaffold({
    required this.child,
    Key? key,
  }) : super(key: key);

  final Widget child;

  @override
  _DemoScaffoldState createState() => _DemoScaffoldState();
}

class _DemoScaffoldState extends State<DemoScaffold> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey.shade800,
          elevation: 0,
          centerTitle: false,
          title: GestureDetector(
            child: const Text('Visual Editor'),
          ),
          actions: [],
        ),
        drawer: Container(
          color: Colors.grey.shade800,
          constraints: BoxConstraints(
            maxWidth: 400,
          ),
          child: NavMenu(),
        ),
        body: SafeArea(
          child: widget.child,
        ),
      );
}
