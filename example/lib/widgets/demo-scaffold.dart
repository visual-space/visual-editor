import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) =>
      Scaffold(
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
          constraints: BoxConstraints(
            maxWidth: MediaQuery
                .of(context)
                .size
                .width * 0.7,
          ),
          color: Colors.grey.shade800,
          child: _menuBar(context),
        ),
        body: SafeArea(
          child: widget.child,
        ),
      );

  Widget _menuBar(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;

    // TODO Separate const containing all the nav options
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _divider(size),
        _navOption(
          title: 'All styles',
          route: '/all-styles',
        ),
        _divider(size),
        _navOption(
          title: 'Read only',
          route: '/read-only',
        ),
        _divider(size),
        _navOption(
          title: 'Multiple Editors',
          route: '/multiple-editors',
        ),
        _divider(size),
      ],
    );
  }

  ListTile _navOption({
    required String title,
    required String route,
  }) {
    return ListTile(
      title: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      onTap: () {
        print('+++ GOTO $route');
        Navigator.pushNamed(context, route);
      },
    );
  }

  Widget _divider(Size size) =>
      Divider(
        thickness: 2,
        color: Colors.white.withOpacity(0.1),
        indent: size.width * 0.1,
        endIndent: size.width * 0.1,
      );

}
