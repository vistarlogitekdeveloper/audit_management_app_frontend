import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';

class ImageService {
  Future<String> compressToMax500Kb(String path) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/audit_${DateTime.now().millisecondsSinceEpoch}.jpg';

    int quality = 90;
    XFile? compressed;

    do {
      compressed = await FlutterImageCompress.compressAndGetFile(
        path,
        targetPath,
        quality: quality,
      );
      quality -= 10;
    } while (compressed != null &&
        File(compressed.path).lengthSync() > AppConstants.maxImageSizeBytes &&
        quality >= 30);

    return compressed?.path ?? path;
  }
}
