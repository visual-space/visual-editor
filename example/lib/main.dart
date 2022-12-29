import 'package:flutter/material.dart';

import 'pages/add-elements.page.dart';
import 'pages/all-styles.page.dart';
import 'pages/custom-styles.page.dart';
import 'pages/custom-toolbar.page.dart';
import 'pages/delete-markers.page.dart';
import 'pages/delta-sandbox.page.dart';
import 'pages/headings.page.dart';
import 'pages/hide-markers-by-type.page.dart';
import 'pages/highlights.page.dart';
import 'pages/limited-length-headings.page.dart';
import 'pages/markers-attachments.page.dart';
import 'pages/markers.page.dart';
import 'pages/multiple-editors.page.dart';
import 'pages/overwrite-controller.page.dart';
import 'pages/placeholder.page.dart';
import 'pages/read-only.page.dart';
import 'pages/selection-menu.page.dart';
import 'pages/wrapping-toolbar.page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DemoApp());
}

// A simple demo app that showcases the Visual Editor in many configurations.
// Follow the code samples in the various demo pages to get better at using the Visual Editor in your project.
class DemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Visual Editor Demo',
      initialRoute: '/all-styles',

      // TODO Add examples for:
      // Exposed utils
      routes: {
        '/all-styles': (context) => AllStylesPage(),
        '/styles': (context) => CustomStylesPage(),
        '/read-only': (context) => ReadOnlyPage(),
        '/multiple-editors': (context) => MultipleEditorsPage(),
        '/custom-toolbar': (context) => CustomToolbarPage(),
        '/wrapping-toolbar': (context) => WrappingToolbarPage(),
        '/placeholder': (context) => PlaceholderPage(),
        '/highlights': (context) => HighlightsPage(),
        '/markers': (context) => MarkersPage(),
        '/markers-attachments': (context) => MarkersAttachmentsPage(),
        '/hide-markers': (context) => HideMarkersByTypePage(),
        '/headings': (context) => HeadingsPage(),
        '/limited-length-headings': (context) => LimitedLengthHeadingsPage(),
        '/delete-markers': (context) => DeleteMarkersPage(),
        '/selection-menu': (context) => SelectionMenuPage(),
        '/delta-sandbox': (context) => DeltaSandbox(),
        '/overwrite-controller': (context) => OverwriteControllerPage(),
        '/add-elements': (context) => AddElementsPage(),
      },
    );
  }
}
