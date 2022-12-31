# Custom embeds
Embeds that are defined by the user and provided to the editor using EditorConfigM when creating VisualEditor. Multiple embed builders can be provided each handling a different kind of embeddable object. Consider looking into the defaultEmbedBuilders for additional examples.

**You must provide an embed builder for each kind of embed present in the document**

```
VisualEditor(
          // additional setup
          config: EditorConfigM(
            // additional setup
            embedBuilders: [
              ...defaultEmbedBuilders,
              BasicEmbedBuilderM(),    // <-- Your custom embed builder
            ],
          ),
);
```

Default embeds are provided for images and videos.

## Basic custom embed
To create a custom embed, a builder needs to be provided. The builder has to implement EmbedBuilderM. I.e.:

```
class BasicEmbedBuilderM implements EmbedBuilderM {
  const BasicEmbedBuilderM();

  @override
  final String key = 'basicEmbed';    // <-- name of the embed key

  @override
  Widget build(    // <-- called when building the embed
    BuildContext context,
    EditorController controller,
    EmbedNodeM node,
    bool readOnly,
  ) =>
      Container(
        height: 100,
        width: 300,
        color: Colors.amber,
        child: Center(
          child: Text(
            'Test demo custom embed',
          ),
        ),
      );
}
```

With the snippet of the embed is represented in Delta format:

```
{
    "insert": {
      "basicEmbed": ""
    }
  }
```

*Note* that the key of the embed is the same as the key in the custom embed builder implementation.

## Reading data from embeddable object
Custom data can be embedded in the document. The example below displays a custom 2x2 image grid with the image urls being embedded in the document.

```
class AlbumEmbedBuilderM implements EmbedBuilderM {
  @override
  String get key => 'album';

  @override
  Widget build(
    BuildContext context,
    EditorController controller,
    EmbedNodeM embed,
    bool readOnly,
  ) =>
      Container(
        height: 500,
        child: _grid(
          children: _getImageUrlsFromEmbed(embed)
              .map(
                _image,
              )
              .toList(),
        ),
      );

  Widget _image(dynamic imageUrl) => Image.network(
        imageUrl,
        width: 100,
        height: 100,
      );

  Widget _grid({required List<Widget> children}) => GridView.count(
        primary: false,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        crossAxisCount: 2,
        children: children,
      );

  List<dynamic> _getImageUrlsFromEmbed(EmbedNodeM embed) {
    final albumEmbeddable = embed.value;
    final imageUrls = jsonDecode(jsonEncode(albumEmbeddable.payload));

    if (imageUrls is List<dynamic>) {
      return imageUrls;
    } else {
      throw UnimplementedError(
        'Album embed payload is not castable to type of List<dynamic>',
      );
    }
  }
}
```

With the following delta embed:

```
{
    "insert": {
      "album": [
        "https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885__480.jpg",
        "https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885__480.jpg",
        "https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885__480.jpg",
        "https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885__480.jpg"
      ]
    }
  },
```

## Inserting custom embeds
Embeddable representations of the embeds have to be provided for each type of custom embed. Below the 2 embeds presented earlier:

```
class EmbeddableCustomWidgetM extends EmbedM {
  EmbeddableCustomWidgetM() : super(customWidgetKey, '');

  static const String customWidgetKey = 'basicEmbed';  // <-- same as the key present in the delta and builder
}
```

```
class AlbumEmbedM extends EmbedM {
  const AlbumEmbedM({required List<String> imageUrls})
      : super('album', imageUrls);
}
```

The second version has to have an payload to embed inside the document. The image URLs is that payload. To insert this an embeddable has to be created and then call the insert function with the embed as the data object. Example below:

```
final embeddableWidget = EmbeddableCustomWidgetM();

_controller.document.insert(
    _controller.selection.start,
    embeddableWidget,
);
```

## Additional info
To better understand embeds, please read about standard embeds and look into the example code provided.

Join on [discord](https://discord.gg/XpGygmXde4) to get advice and help or follow us on [YouTube Visual Coding](https://www.youtube.com/channel/UC2-5lfNbbErIds0Iuai8yfA) to learn more about the architecture of Visual Editor and other Flutter apps.