import 'package:flutter/material.dart';

import '../const/nav-menu.const.dart';
import '../models/nav-menu-link.model.dart';

// Navigation between all the demo page
class NavMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _navMenu(
        children: [
          _divider(),
          for (final link in NAV_MENU) ...[
            _navOption(link, context),
            _divider(),
          ],
        ],
      );

  Widget _navMenu({required List<Widget> children}) => SingleChildScrollView(
        controller: ScrollController(),
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 40, 10, 40),
          child: Column(
            children: children,
          ),
        ),
      );

  ListTile _navOption(
    NavMenuLinkM link,
    BuildContext context,
  ) {
    final title = link.title;
    final route = link.route;

    return ListTile(
      title: Container(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }

  Widget _divider() => Divider(
        thickness: 2,
        color: Colors.white.withOpacity(0.1),
      );
}
