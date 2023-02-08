import 'package:flutter/material.dart';

import 'nav-menu.dart';

// Scaffold used by all pages in the demo app.
// It provides the navigation menu used to navigate between examples.
class DemoPageScaffold extends StatelessWidget {
  final Widget child;
  final List<Widget>? actions;
  final double? pageWidth;

  const DemoPageScaffold({
    required this.child,
    this.actions,
    this.pageWidth,
  }) : super();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _appBar(
          title: _title(),
        ),
        drawer: _navMenu(),
        body: _centerSafeArea(),
      );

  AppBar _appBar({
    required Widget title,
  }) =>
      AppBar(
        backgroundColor: Colors.grey.shade800,
        elevation: 0,
        centerTitle: false,
        title: title,
        actions: actions,
      );

  Widget _title() => Text('Visual Editor');

  Widget _navMenu() => Container(
        color: Colors.grey.shade800,
        constraints: BoxConstraints(
          maxWidth: 400,
        ),
        child: NavMenu(),
      );

  Center _centerSafeArea() {
    return Center(
      child: Container(
        width: pageWidth ?? 900,
        child: SafeArea(
          child: child,
        ),
      ),
    );
  }
}
