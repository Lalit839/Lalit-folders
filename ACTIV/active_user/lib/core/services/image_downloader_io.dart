import 'dart:io';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> downloadImageFile(String fileName, Uint8List bytes) async {
  final dir = await Directory.systemTemp.createTemp('activ_share');
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path, mimeType: 'image/png')]),
  );
}