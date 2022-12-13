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

