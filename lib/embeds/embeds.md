# Embeds
Visual Editor can display arbitrary custom components inside of the documents such as: image, video, tweets, etc. An embed node has a length of 1 character. Any inline style can be applied to an embed, however this does not necessarily mean the embed will look according to that style. For instance, applying "bold" style to an image gives no effect, while adding a "link" to an image actually makes the image react to user's action. Custom embed builders can be provided to render custom elements in the page.

```json
{
  "insert": {
    "image": "https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885__480.jpg"
  }
}
```


## Architecture (WIP)
- **EmbedM** - (WIP)


## EmbedBuilderM (WIP)
EmbedBuilderM is an interface that the Visual Editor uses to display embeds. Every kind of embeddable object has an EmbedBuilderM implementation.

```dart
abstract class EmbedBuilderM {
  String get key;

  Widget build(
    BuildContext context,
    EditorController controller,
    EmbedNodeM embed,
    bool readOnly,
  );
}
```

**Video embed**
```dart
class ImageEmbedBuilderM implements EmbedBuilderM {
  const ImageEmbedBuilderM();

  @override
  final String key = ImageEmbedM.imageKey;

  @override
  Widget build(){
    // ...
  }
}
```


## EmbedBuilderController (WIP)


## Custom embeds (WIP)

