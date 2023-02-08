### Visual Editor Cookbook

Here are presented basic operations that can be done using editor controller methods.

# Insert new elements at the end of the document

For example if you want to have a button that every time is pressed adds a new empty line at the end of the document we can simply replace the last element of the document with the empty line. 

 ```dart
final docLen = _controller.document.length;
_controller.replaceText(docLen - 1, 0, '\n', null);
```

# How to apply attributes to text via the controller

The attributes are used to apply a different style to a piece of text (bold, italic, etc.). Everything which is not simple text has at least an attribute. To apply attributes without directly interacting with the text (i.e by pressing a button) we can call the format text method from the controller with the desired attribute. 
 ```dart
 _controller.formatText(docLen, 0, AttributesAliasesM.h1);
```

Here we apply the h1 attribute to the empty line created above. In this way, by pressing a single button we can create a new empty line with h1 attribute

# How to implement limited length headings

First of all we have to extract all headings of the page. We already have a method on the controller that does this for us. The recommended way to call this method is every time the build is done. In this way, we will always have access to the latest headings of the document. 
Then we have to compare every headings length with our limit. If the limit is exceeded we have to create a counter (they will be displayed near every heading which exceeds the limit).

```dart
const CHARACTERS_LIMIT = 30;

_headingsList.forEach((heading) {
  // The editor returns an additional invisible char ('\n') so we have to subtract it
  final headerLength = (heading.text?.length ?? 0) - 1;

  // Check if headers exceed the limit and create counters
  if (headerLength > CHARACTERS_LIMIT) {
    // The position of the counter in the delta document without any additional dimension
    final rawPosition =
        heading.docRelPosition!.dy + (heading.rectangles?.last.bottom ?? 0);

    _counters.add(
      CharacterCounterM(
        count: headerLength - CHARACTERS_LIMIT,
        yPosition: rawPosition,
      ),
    );
  }
});
```

After that we will have to highlight the extra characters. For this we already have a method prepared on the controller.

```dart
const CHARACTERS_LIMIT = 30;

_headingsList.forEach((heading) {
  // The editor returns an additional invisible char ('\n') so we have to subtract it
  final headerLength = (heading.text?.length ?? 0) - 1;

  // Check if headers exceed the limit and create counters
  if (headerLength > CHARACTERS_LIMIT) {
    final baseOffset = heading.selection?.baseOffset ?? 0;
    final extentOffset = heading.selection?.extentOffset ?? 0;
    // The position of the counter in the delta document without any additional dimension
    final rawPosition = heading.docRelPosition!.dy + (heading.rectangles?.last.bottom ?? 0);
    
    _controller.addHighlight(
      HighlightM(
        id: 'id',
        color: Colors.red.withOpacity(0.3),
        hoverColor: Colors.red.withOpacity(0.3),
        textSelection: TextSelection(
          baseOffset: baseOffset + CHARACTERS_LIMIT,
          extentOffset: extentOffset,
        ),
      ),
    );
  }
});
```

Once we have all counters created we have to get the floating effect. They are put over the editor in a stack so every time the editor changes (is scrolled or the text is edited) we have to update the counters position.

```dart
void _updateCountersPosition(double scrollControllerOffset) {
  final updatedCountersList = <CharacterCounterM>[];
  const textHeight = 15;

  _counters.forEach((counter) {
    updatedCountersList.add(
      counter.copyWith(
        yPosition: counter.yPosition! - textHeight - scrollControllerOffset,
      ),
    );
  });

  _counters$.add(updatedCountersList);
}
```

For better understanding of this implementation we have to check the LimitedLengthHeadingsPage.