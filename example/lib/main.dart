import 'package:flutter/material.dart';

import 'controller/pages/add-elements.page.dart';
import 'controller/pages/headings-validation.page.dart';
import 'controller/pages/headings.page.dart';
import 'developer/pages/delta-sandbox.page.dart';
import 'developer/pages/multiple-editors.page.dart';
import 'developer/pages/overwrite-controller.page.dart';
import 'developer/pages/parent-scroll.page.dart';
import 'embeds/pages/custom-embeds.page.dart';
import 'interactions/pages/selection-menu.page.dart';
import 'markers/pages/delete-markers.page.dart';
import 'markers/pages/hide-markers.page.dart';
import 'markers/pages/highlights.page.dart';
import 'markers/pages/markers-attachments.page.dart';
import 'markers/pages/markers.page.dart';
import 'styles/pages/all-styles.page.dart';
import 'styles/pages/custom-styles.page.dart';
import 'styles/pages/placeholder.page.dart';
import 'styles/pages/read-only.page.dart';
import 'toolbar/pages/custom-toolbar.page.dart';
import 'toolbar/pages/wrapping-toolbar.page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DemoApp());
}

// A simple demo app that showcases the Visual Editor in many configurations.
// Follow the code samples in the various demo pages to get better at using the Visual Editor in your project.
class DemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Visual Editor Demo',
        initialRoute: '/all-styles',
        routes: {
          // Styles
          '/all-styles': (context) => AllStylesPage(),
          '/styles': (context) => CustomStylesPage(),
          '/read-only': (context) => ReadOnlyPage(),
          '/placeholder': (context) => PlaceholderPage(),

          // Toolbar
          '/custom-toolbar': (context) => CustomToolbarPage(),
          '/wrapping-toolbar': (context) => WrappingToolbarPage(),

          // Markers
          '/highlights': (context) => HighlightsPage(),
          '/markers': (context) => MarkersPage(),
          '/markers-attachments': (context) => MarkersAttachmentsPage(),
          '/hide-markers': (context) => HideMarkersPage(),
          '/delete-markers': (context) => DeleteMarkersPage(),

          // Interactions
          '/selection-menu': (context) => SelectionMenuPage(),

          // Embeds
          '/custom-embeds': (context) => CustomEmbedsPage(),

          // Controller
          '/headings': (context) => HeadingsPage(),
          '/headings-validation': (context) => HeadingsValidationPage(),
          '/add-elements': (context) => AddElementsPage(),

          // Developer
          '/delta-sandbox': (context) => DeltaSandboxPage(),
          '/multiple-editors': (context) => MultipleEditorsPage(),
          '/overwrite-controller': (context) => OverwriteControllerPage(),
          '/parent-scroll':(context) => ParentScrollPage(),
        },
      );
}
