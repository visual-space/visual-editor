import 'dart:io';

import 'package:flutter/material.dart';

import 'media-pick.enum.dart';

typedef OnImagePickCallback = Future<String?> Function(File file);
typedef OnVideoPickCallback = Future<String?> Function(File file);
typedef FilePickImpl = Future<String?> Function(BuildContext context);
typedef WebImagePickImpl = Future<String?> Function(
  OnImagePickCallback onImagePickCallback,
);
typedef WebVideoPickImpl = Future<String?> Function(
  OnVideoPickCallback onImagePickCallback,
);
typedef MediaPickSettingSelector = Future<MediaPickSettingE?> Function(
  BuildContext context,
);
