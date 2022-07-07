import 'package:flutter/material.dart';

// A marker defines it's type (class) and additional data.
// The "data" attribute stores custom params as desired by the client app (uuid or serialised json data).
// It's up to the client app to decide how to use the data attribute.
// One idea is to use UUIDS that point to a separate list of entries which describe the various attributes of a marker.
// For example a developer might want to render a bunch of stats that are repeating on a large set of the markers of the app.
// Therefore instead of repeating the same data inline in the entire doc it's better to reference these values from a separate list.
// In this case using the data to store an UUID will be good enough.
// On the other hand, if the dev knows that most of the markers will have few
// and unique attributes than he can store the attributes in the "data" attribute itself.
// The "data" attribute will be returned by the callbacks methods invoked on hover and tap.
// Multiple markers can use the same "data" values to trigger the same common behaviours.
// In essence there are many ways this attribute can be put to good use.
// It's also possible not to use it at all and just render highlights that don't have any unique data assigned.
@immutable
class MarkerM {
  final String type;
  final dynamic data;

  MarkerM(
    this.type, [
    this.data,
  ]);

  Map<String, dynamic> toJson() => {
    'type': type,
    if (data != null) 'data': data,
  };

  @override
  String toString() {
    return 'MarkerM(type: $type, data: $data)';
  }
}
