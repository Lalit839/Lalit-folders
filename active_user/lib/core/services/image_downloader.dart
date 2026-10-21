import 'dart:typed_data';

import 'image_downloader_stub.dart'
    if (dart.library.html) 'image_downloader_web.dart'
    if (dart.library.io) 'image_downloader_io.dart' as impl;

Future<void> downloadImageFile(String fileName, Uint8List bytes) =>
    impl.downloadImageFile(fileName, bytes);