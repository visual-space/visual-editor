import 'package:flutter/cupertino.dart';

import '../../documents/models/attributes/attributes.model.dart';

Map<String, String> parseKeyValuePairs(String string, Set<String> targetKeys) {
  final result = <String, String>{};
  final pairs = string.split(';');

  for (final pair in pairs) {
    final _index = pair.indexOf(':');

    if (_index < 0) {
      continue;
    }

    final _key = pair.substring(0, _index).trim();

    if (targetKeys.contains(_key)) {
      result[_key] = pair.substring(_index + 1).trim();
    }
  }

  return result;
}

String replaceStyleString(
  String string,
  double width,
  double height,
) {
  final result = <String, String>{};
  final pairs = string.split(';');

  for (final pair in pairs) {
    final _index = pair.indexOf(':');

    if (_index < 0) {
      continue;
    }

    final _key = pair.substring(0, _index).trim();
    result[_key] = pair.substring(_index + 1).trim();
  }

  result[AttributesM.mobileWidth] = width.toString();
  result[AttributesM.mobileHeight] = height.toString();
  final sb = StringBuffer();

  for (final pair in result.entries) {
    sb
      ..write(pair.key)
      ..write(': ')
      ..write(pair.value)
      ..write('; ');
  }

  return sb.toString();
}

Alignment getAlignment(String? string) {
  const _defaultAlignment = Alignment.center;

  if (string == null) {
    return _defaultAlignment;
  }

  final _index = [
    'topLeft',
    'topCenter',
    'topRight',
    'centerLeft',
    'center',
    'centerRight',
    'bottomLeft',
    'bottomCenter',
    'bottomRight'
  ].indexOf(string);

  if (_index < 0) {
    return _defaultAlignment;
  }

  return [
    Alignment.topLeft,
    Alignment.topCenter,
    Alignment.topRight,
    Alignment.centerLeft,
    Alignment.center,
    Alignment.centerRight,
    Alignment.bottomLeft,
    Alignment.bottomCenter,
    Alignment.bottomRight
  ][_index];
}

// Just a word of caution: this does not rely on strong random data.
// Therefore, the generated UUIDs should not be considered cryptographically strong.
String getTimeBasedId() {
  final now = DateTime.now();
  return now.microsecondsSinceEpoch.toString();
}