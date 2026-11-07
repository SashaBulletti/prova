import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

Future<String> persistPhoto(XFile file, String id) async => file.path;

Future<void> deletePhoto(String path) async {}

Widget photoImage(String path, {BoxFit fit = BoxFit.cover}) => Image.network(
      path,
      fit: fit,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
