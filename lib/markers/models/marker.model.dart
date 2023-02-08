import 'package:flutter/material.dart';

// Used to render permanent highlights on top of document.
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
  // Markers with the same id will be considered a single marker even though they are positioned in different parts of the document.
  // Because of this they will react at the same time during interactions (hover, delete, etc.)
  final String id;
  final String type;

  // Let's assume you want to link the profile of a particular user to one or more arbitrary markers
  // (for example to render a user card on top of the marker on hovering).
  // The "data" attribute stores custom params as desired by the client app (uuid or serialised json data).
  // It's up to the client app to decide how to use the data attribute.
  // One idea is to use UUIDs that point to separate objects which provide additional info for a marker.
  // For example a developer might want to render a bunch of statistics (or an user profile)
  // that are repeating on a large set of the markers of the app.
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
  // An additional model was created to make a clear distinction between the marker as retrieved from the delta document (MarkerM)
  // and the markers that have been rendered and their coordinates are now known.
  // (!) Added at runtime
  final List<TextBox>? rectangles;

  // Global position relative to the viewport of the EditableTextLine that contains the marker.
  // We don't expose the full TextLine to avoid access from the public scope to the private scope.
  // (!) Added at runtime
  final Offset? docRelPosition;

  // When reading the delta json we want to understand from which chars up to which chars the marker is defined.
  // (!) Added at runtime
  final TextSelection? textSelection;

  MarkerM({
    required this.id,
    required this.type,
    this.data,
    this.rectangles,
    this.docRelPosition,
    this.textSelection,
  });

  // (!) Only the static data, no runtime props here
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        if (data != null) 'data': data,
        // We don't want to add the runtime data (textSelection, docRelPosition, rectangles)
        // because that is a projection of data already
        // encoded in the way the text was sliced into operations.
      };

  @override
  String toString() {
    return 'MarkerM('
        'id: $id, '
        'type: $type, '
        'data: $data, '
        'rectangles: $rectangles,'
        'docRelPosition: $docRelPosition,'
        'textSelection: $textSelection,'
      ')';
  }

  MarkerM copyWith({
    String? id,
    String? type,
    dynamic data,
    List<TextBox>? rectangles,
    Offset? docRelPosition,
    TextSelection? textSelection,
  }) =>
      MarkerM(
        id: id ?? this.id,
        type: type ?? this.type,
        data: data ?? this.data,
        rectangles: rectangles ?? this.rectangles,
        docRelPosition: docRelPosition ?? this.docRelPosition,
        textSelection: textSelection ?? this.textSelection,
      );
}
