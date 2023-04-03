import '../models/nav-menu-category.model.dart';
import '../models/nav-menu-link.model.dart';

const List<NavMenuCategoryM> NAV_MENU = [
  // === STYLES ===

  NavMenuCategoryM(
    title: 'Styles',
    links: [
      NavMenuLinkM(
        title: 'All Styles',
        route: '/all-styles',
      ),
      NavMenuLinkM(
        title: 'Custom styles',
        route: '/styles',
      ),
      NavMenuLinkM(
        title: 'Read Only',
        route: '/read-only',
      ),
      NavMenuLinkM(
        title: 'Placeholder',
        route: '/placeholder',
      ),
    ],
  ),

  // === TOOLBAR ===

  NavMenuCategoryM(
    title: 'Toolbar',
    links: [
      NavMenuLinkM(
        title: 'Custom Toolbar',
        route: '/custom-toolbar',
      ),
      NavMenuLinkM(
        title: 'Wrapping Toolbar',
        route: '/wrapping-toolbar',
      ),
    ],
  ),

  // === MARKERS ===

  NavMenuCategoryM(
    title: 'Markers',
    links: [
      NavMenuLinkM(
        title: 'Highlights',
        route: '/highlights',
      ),
      NavMenuLinkM(
        title: 'Markers',
        route: '/markers',
      ),
      NavMenuLinkM(
        title: 'Markers Attachments',
        route: '/markers-attachments',
      ),
      NavMenuLinkM(
        title: 'Hide Markers By Type',
        route: '/hide-markers',
      ),
      NavMenuLinkM(
        title: 'Delete Markers',
        route: '/delete-markers',
      ),
    ],
  ),

  // === INTERACTIONS ===

  NavMenuCategoryM(
    title: 'Interactions',
    links: [
      NavMenuLinkM(
        title: 'Selection Menu',
        route: '/selection-menu',
      ),
      // TODO Custom controls
      // TODO User Card on hover
      // TODO Hashtags
      // TODO At Notation
      // TODO Slash Commands
    ],
  ),

  // === EMBEDS ===

  NavMenuCategoryM(
    title: 'Embeds',
    links: [
      // TODO Images & Video
      NavMenuLinkM(
        title: 'Custom Embeds',
        route: '/custom-embeds',
      ),
      // TODO Formula
    ],
  ),

  // === CONTROLLER ===

  NavMenuCategoryM(
    title: 'Controller',
    links: [
      // TODO Controller Callbacks
      NavMenuLinkM(
        title: 'Headings',
        route: '/headings',
      ),
      NavMenuLinkM(
        title: 'Limited Length Headings',
        route: '/headings-validation',
      ),
      NavMenuLinkM(
        title: 'Add Elements',
        route: '/add-elements',
      ),
    ],
  ),

  // === DEVELOPMENT ===

  NavMenuCategoryM(
    title: 'Development',
    links: [
      NavMenuLinkM(
        title: 'Delta sandbox',
        route: '/delta-sandbox',
      ),
      NavMenuLinkM(
        title: 'Multiple Editors',
        route: '/multiple-editors',
      ),
      NavMenuLinkM(
        title: 'Multiple Editors With Parent Scroll',
        route: '/parent-scroll',
      ),
      NavMenuLinkM(
        title: 'Overwrite Controller',
        route: '/overwrite-controller',
      ),
    ],
  ),
];
