# Embeds
Visual Editor can display any custom component inside of the documents.

An embed node inside of a line in a Quill document. Embed node is a leaf node similar to Text. It represents an arbitrary piece of non-textual blocks embedded into a document, such as, image, video, or any other object with defined structure, like a tweet, for instance.

Embed node's length is always `1` character and it is represented with unicode object replacement character in the document text. **Embed copy-paste is planned, for more information follow ticket [#8](https://github.com/visual-space/visual-editor/issues/8)**.

Any inline style can be applied to an embed, however this does not necessarily mean the embed will look according to that style. For instance, applying "bold" style to an image gives no effect, while adding a "link" to an image actually makes the image react to user's action.

## Data flow
Data that is parsed from the delta json is normalized (converted to models) before inserting into the document. This ensures that any embedded objects are converted into EmbedM type when new content is added to the document.

```
Object _normalize(Object? data) {
    if (data is String) {
      return data;
    } else if (data is EmbedM) {
      return data;
    }

    return EmbedM.fromObject(data);
  }
```

### EmbedM
EmbedM is data which can be decoded or encoded into a delta document; meaning: it is embeddable. EmbedM is the data that is held as value of embed node. This provides a standard model to insert and retrieve embeddable data from the document.

```
class EmbedM {
  const EmbedM(this.type, this.payload);

  // The type of this object.
  final String type;

  // The data payload of this object.
  final dynamic payload;

  Map<String, dynamic> toJson() {
    return {type: payload};
  }

/.../
}
```

`type` is the key of the embeddable that is represented in the delta json; i.e. image embed has the type of "image":

```
{
    "insert": {
      "image": "https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885__480.jpg"
    },
  },
```

`payload` is data that is inserted into the delta json. Such data is dynamic because different embeds require different data to function. I.e. the payload of an image embed is the image URL.

To create embeddable data, create a class that extends EmbedM. Below an example of how images are represented in the document:

```
class ImageEmbedM extends EmbedM {
  ImageEmbedM(String imageUrl) : super(imageKey, imageUrl);

  static const String imageKey = 'image';
}
```

To insert embeds into the document, create the require embed and `replace` passing the data as an embed node.

```
final imageEmbed = ImageEmbedM(imageUrl);
final index = _controller.selection.baseOffset;
final length = _controller.selection.extentOffset - index;

_controller.replace(
    index,
    length,
    embeddableWidget,
    null,
);
```

## EmbedBuilderM
EmbedBuilderM is an interface that the Visual Editor uses to display embeds. Every kind of embeddable object has an EmbedBuilderM implementation.

```
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

To create a builder for a custom embed, implement EmbedBuilderM. Below the implementation for video embeds is presented:

```
class ImageEmbedBuilderM implements EmbedBuilderM {
  const ImageEmbedBuilderM();

  @override
  final String key = ImageEmbedM.imageKey;

  @override
  Widget build(
    BuildContext context,
    EditorController controller,
    EmbedNodeM embed,
    bool readOnly,
  ) {
    /.../
  }
}
```

**Note!**
`key` is the same as the ImageEmbedM, as well as the key that is parsed from the delta json.

**Avoid providing multiple builders with the same key.**

`build()` is called whenever the widget is painted in the editor, **do not keep stateful data** because it will get deleted between builds.

## EmbedBuilderController
The main component that handles the selection of the embed builder. This component looks for pairs of the Embeddable `type` (key in the delta json) and the key of the `EmbedBuilder`. I.e. for the embed with the type of `'image'` it will return the `build()` of the `ImageEmbedBuilderM` because the `key` matches the `type`.

It gets initialized in the TextLine and keeps an internal state of the available embed builders.

## Layout
Embeds will take up the whole text line if inserted on an empty line or as a `WidgetSpan` if inserted in a line with elements already present.

To learn more about creating custom embeds, read `custom-embeds.md`.


Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.