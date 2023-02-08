import 'package:flutter/cupertino.dart';

import 'nav-menu-link.model.dart';

@immutable
class NavMenuCategoryM {
  final String title;
  final List<NavMenuLinkM> links;

  const NavMenuCategoryM({
    required this.title,
    required this.links,
  });
}
