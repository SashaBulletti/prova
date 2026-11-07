import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<String> persistPhoto(XFile file, String id) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/photos');
  if (!await dir.exists()) await dir.create(recursive: true);
  final target = '${dir.path}/$id-${DateTime.now().millisecondsSinceEpoch}.jpg';
  await File(file.path).copy(target);
  return target;
}

Future<void> deletePhoto(String path) async {
  try {
    final f = File(path);
    if (await f.exists()) await f.delete();
  } catch (_) {}
}

Widget photoImage(String path, {BoxFit fit = BoxFit.cover}) => Image.file(
      File(path),
      fit: fit,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
