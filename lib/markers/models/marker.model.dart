import 'package:flutter/material.dart';

// Used to render permanent highlights on top of documents.
// Added manually via the toolbar and programmatically via the controller.
// Removed manually using an attached widget or programmatically via the controller.
// Widget attachments can be linked to the position of a widget using the pixel coordinates data.
// Read more in markers.md
@immutable
class MarkerM {
  // We need ids, otherwise we don't have a reliable means of deleting
  // arbitrary markers from a stack of markers that share the same text span.
  // We would be forced to delete only markers from the top.
  // Without the id a client developer would have to navigate by himself
  // to the marker node that he needs to delete (which is not fun).
  // (!) If you need to link one object to multiple marker consider
  // using the data attribute as a shared identifier.
  final String id;
  final String type;

  // The "data" attribute stores custom params as desired by the client app (uuid or serialised json data).
  // It's up to the client app to decide how to use the data attribute.
  // One idea is to use UUIDS that point to separate objects which provide additional info for a marker.
  // For example a developer might want to render a bunch of stats that are repeating on a large set of the markers of the app.
  // Therefore instead of repeating the same data inline in the entire doc it's better to reference these values from a separate list.
  // In this case using the data to store an UUID for the descriptor object will be enough.
  // On the other hand, if the dev knows that most of the markers will have few
  // and unique attributes than he can store the attributes in the "data" attribute itself.
  // The "data" attribute will be returned by the callbacks methods invoked on hover and tap.
  // Multiple markers can use the same "data" values to trigger the same common behaviours.
  // In essence there are many ways this attribute can be put to good use.
  // It's also possible not to use it at all and just render highlights that don't have any unique data assigned.
  final dynamic data;

  // At initialisation the editor will parse the delta document and will start rendering the text lines one by one.
  // Each EditableTextLine renders the markers belonging to that particular LineM.
  // When drawing each marker we retrieve the rectangles and the relative position of the text line.
  // This information is essential for rendering marker attachments after the editor build is completed.
  // (!) Added at runtime
  final List<TextBox>? rectangles;

  // Global position relative to the viewport of the EditableTextLine that contains the marker.
  // We don't expose the full TextLine to avoid access from the public scope to the private scope.
  // (!) Added at runtime
  final Offset? docRelPosition;

  MarkerM({
    required this.id,
    required this.type,
    this.data,
    this.rectangles,
    this.docRelPosition,
  });

  // (!) Only the static data, no runtime props here
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        if (data != null) 'data': data,
      };

  @override
  String toString() {
    return 'MarkerM('
        'id: $id, '
        'type: $type, '
        'data: $data, '
        'rectangles: $rectangles,'
        'docRelPosition: $docRelPosition,'
        ')';
  }

  MarkerM copyWith({
    String? id,
    String? type,
    dynamic data,
    List<TextBox>? rectangles,
    Offset? docRelPosition,
  }) =>
      MarkerM(
        id: id ?? this.id,
        type: type ?? this.type,
        data: data ?? this.data,
        rectangles: rectangles ?? this.rectangles,
        docRelPosition: docRelPosition ?? this.docRelPosition,
      );
}
