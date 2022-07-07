import 'package:flutter/material.dart';

import '../const/nav-menu.const.dart';

// Navigation between all the demo page
class NavMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: double.infinity,
      padding: EdgeInsets.fromLTRB(10, 90, 10, 90),
      child: SingleChildScrollView(
        controller: ScrollController(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _divider(size),
            for (final link in NAV_MENU) ...[
              _navOption(
                title: link.title,
                route: link.route,
                context: context,
              ),
              _divider(size),
            ],
          ],
        ),
      ),
    );
  }

  ListTile _navOption({
    required String title,
    required String route,
    required BuildContext context,
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
        Navigator.pushNamed(context, route);
      },
    );
  }

  Widget _divider(Size size) => Divider(
        thickness: 2,
        color: Colors.white.withOpacity(0.1),
        // indent: size.width * 0.1,
        // endIndent: size.width * 0.1,
      );
}
