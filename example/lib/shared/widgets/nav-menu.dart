import 'package:flutter/material.dart';

import '../const/nav-menu.const.dart';
import '../models/nav-menu-link.model.dart';

// Navigation between all the demo page
class NavMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _scrollCol(
        children: [
          for (final category in NAV_MENU)
            _category(
              title: category.title,
              links: [
                for (final link in category.links) _link(link, context),
              ],
            ),
        ],
      );

  Widget _scrollCol({required List<Widget> children}) => SingleChildScrollView(
        controller: ScrollController(),
        child: Container(
          padding: EdgeInsets.fromLTRB(0, 40, 10, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );

  Widget _category({
    required String title,
    required List<Widget> links,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, 32, 20, 4),
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...links,
        ],
      );

  Widget _link(
    NavMenuLinkM link,
    BuildContext context,
  ) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          hoverColor: Colors.white.withOpacity(0.2),
          child: Container(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                link.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, link.route);
          },
        ),
      );
}
