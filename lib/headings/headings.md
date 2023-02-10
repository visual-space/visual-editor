# Headings (WIP)
All lines of text marked with first level header attribute, packed with their position in the document. They are extracted and stored in the state store and a customized behavior can be applied to them.


## Data Model
**heading.model.dart**
```dart
@immutable
class HeadingM {
  final String? text;
  final Offset? docRelPosition;
  final List<TextBox>? rectangles;
  final TextSelection? selection;

  const HeadingM({
    this.text,
    this.docRelPosition,
    this.rectangles,
    this.selection,
  });
}
```


## Extracting Headings
After the first build, we iterate through every line of a document and look for the first-level header attribute. After that we store them in the state store. Every modification of the document will trigger again this method so the list of headings will be updated immediately.


## How to access headings
Headings are stored in HeadingsState state store and are permanently updated. They are easily accessed using the controller. After this, they will behave as a normal list.

```dart
 final headings = _controller?.getAllHeadings();
```


## Heading position
Every heading is packed with its current position in the document. Because of this it is easy to implement features like scroll to tapped heading position.

```dart
 void _scrollToTheHeadingPosition(HeadingM heading) {
    final headingPosition = (heading.docRelPosition?.dy ?? 0) - _topBarOffset;

    widget.scrollController?.animateTo(
      headingPosition,
      duration: Duration(milliseconds: 300),
      curve: Curves.linear,
    );
  }
```


## How to implement limited length headings
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

