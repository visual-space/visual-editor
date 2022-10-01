import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_editor/blocks/widgets/text-line-styles.utils.dart';
import 'package:visual_editor/documents/models/attributes/attributes-aliases.model.dart';
import 'package:visual_editor/visual-editor.dart';

var RTL_TEXT_MOCK = '''[
  {
    "insert": "\\n",
    "attributes": {
      "align": "right",
      "direction": "rtl"
    }
  }
]''';

MaterialApp buildPage(EditorController controller) {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          buildEditor(controller),
          buildRTLToolbar(controller),
        ],
      ),
    ),
  );
}

VisualEditor buildEditor(EditorController controller) {
  return VisualEditor(
    controller: controller,
    scrollController: ScrollController(),
    focusNode: FocusNode(),
    config: EditorConfigM(autoFocus: true),
  );
}

EditorToolbar buildRTLToolbar(EditorController controller) {
  return EditorToolbar.basic(
    controller: controller,

    /// Disable all buttons except RTL button
    multiRowsDisplay: false,
    showDividers: false,
    showFontSize: false,
    showBoldButton: false,
    showItalicButton: false,
    showSmallButton: false,
    showUnderLineButton: false,
    showStrikeThrough: false,
    showInlineCode: false,
    showColorButton: false,
    showBackgroundColorButton: false,
    showClearFormat: false,
    showAlignmentButtons: true,
    showHeaderStyle: false,
    showListNumbers: false,
    showListBullets: false,
    showListCheck: false,
    showCodeBlock: false,
    showQuote: false,
    showIndent: false,
    showLink: false,
    showUndo: false,
    showRedo: false,
    showImageButton: false,
    showVideoButton: false,
    showCameraButton: false,
    showMarkers: false,
    showLeftAlignment: false,
    showCenterAlignment: false,
    showRightAlignment: false,
    showJustifyAlignment: false,

    /// Enable RTL
    showDirection: true,
  );
}

void main() {
  late DocumentM document;
  late Widget rtlPage;
  late EditorController controller;

  setUp((){
    document = DocumentM.fromJson(jsonDecode(RTL_TEXT_MOCK));
  });

  group('Editor Support RTL', () {
    group('Json to Delta', () {
      test(
          'Given document loaded from json '
          'With nodes containing attributes: align:right and direction:rtl '
          "Then node's attributes align=right and direction=rtl "
          '', () {
        /// ARRANGE - Set up everything needs to be used by the test.


        /// ACT - Call the specific method / change to test on.
        final nodeStyle = document.root.children.first.style;

        /// ASSERT - Check values.
        expect(true, nodeStyle.attributes.isNotEmpty);
        expect(nodeStyle.attributes.keys.contains('align'), true);
        expect(nodeStyle.attributes['align']!.value, 'right');

        expect(nodeStyle.attributes.keys.contains('direction'), true);
        expect(nodeStyle.attributes['direction']!.value, 'rtl');
      });
    });

    group('Internal-Logic', () {
      test(
          'Given TextLineStyleUtils '
          'With leftAlignment and TextDirection.rtl '
          'Then TextAlign should be Text.End', () {
        /// ARRANGE
        final textLineUtil = TextLineStyleUtils();

        /// ACT
        final res = textLineUtil.getTextAlign(
            AttributesAliasesM.leftAlignment, TextDirection.rtl);

        /// ASSERT
        expect(res, TextAlign.end);
      });
      test(
          'Given TextLineStyleUtils '
          'With rightAlignment and TextDirection.rtl '
          'Then TextAlign should be Text.Start', () {
        /// ARRANGE
        final textLineUtil = TextLineStyleUtils();

        /// ACT
        final res = textLineUtil.getTextAlign(
            AttributesAliasesM.rightAlignment, TextDirection.rtl);

        /// ASSERT
        expect(res, TextAlign.start);
      });
    });

    group('ToolBar', () {
      testWidgets(
          'Given ToolBarEditor '
          'With direction enabled '
          'Then button appears in Toolbar', (WidgetTester tester) async {
        /// ARRANGE
        // Page with buttons enabled
        controller = EditorController(document: document);
        rtlPage = buildPage(controller);


        /// ACT
        await tester.pumpWidget(rtlPage);
        await tester.pumpAndSettle();
        final buttonRTL = find.byKey(ValueKey('buttonRTL'));

        /// ASSERT - check value
        expect(buttonRTL, findsOneWidget);
      });
      testWidgets(
          'Given Editor '
          'With left to right document '
          'Then trigger direction button in ToolBar changes attribute to right to left',
          (WidgetTester tester) async {
        /// ARRANGE
        final document = DocumentM.fromJson(jsonDecode(RTL_TEXT_MOCK));
        final controller = EditorController(document: document);
        rtlPage = buildPage(controller);

        /// ACT
        await tester.pumpWidget(rtlPage);
        await tester.pumpAndSettle();

        final buttonRTL = find.byKey(ValueKey('buttonRTL'));
        await tester.tap(buttonRTL);
        await tester.pumpAndSettle();
        final Map<String, dynamic> blockStyle = controller.document
            .toDelta()
            .toJson()
            .firstWhere((element) => element['insert'] == "\n");
        expect(blockStyle['attributes']['direction'], null);
      });
    });
  });
}
