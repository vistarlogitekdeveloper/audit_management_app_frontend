import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';

class ImageService {
  Future<String> compressToMax500Kb(String path) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;

    XFile? compressed;
    for (int quality = 90; quality >= 30; quality -= 10) {
      // flutter_image_compress will not overwrite an existing destination
      // file (it returns null), so every attempt must use a distinct path —
      // otherwise the loop silently stops after the first pass and oversized
      // images get uploaded unchanged.
      final targetPath = '${dir.path}/audit_${stamp}_q$quality.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        targetPath,
        quality: quality,
      );
      if (result == null) break;
      compressed = result;
      if (File(result.path).lengthSync() <= AppConstants.maxImageSizeBytes) {
        break;
      }
    }

    return compressed?.path ?? path;
  }
}
