import 'package:flutter/material.dart';

import 'pages/all-styles.page.dart';
import 'pages/multiple-editors.page.dart';
import 'pages/read-only.page.dart';

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
      // Custom styles
      // Custom toolbar
      // Highlights
      // Exposed utils
      routes: {
        '/all-styles': (context) => AllStylesPage(),
        '/read-only': (context) => ReadOnlyPage(),
        '/multiple-editors': (context) => MultipleEditorsPage(),
      },
    );
  }
}
