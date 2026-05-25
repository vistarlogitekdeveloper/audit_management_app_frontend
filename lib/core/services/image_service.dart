import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';

class ImageService {
  /// Compresses the image at [path] down to at most
  /// [AppConstants.maxImageSizeBytes] (500 KB), which the backend now enforces
  /// strictly (multer rejects anything larger). Strategy, in order:
  ///   1. Drop JPEG quality 90 → 30 (step 10) at full resolution.
  ///   2. If still oversized, scale to max 1280×1280 @ quality 60.
  ///   3. If still oversized, scale to max 800×800 @ quality 50.
  ///
  /// Post-condition: the returned file is ≤ [AppConstants.maxImageSizeBytes],
  /// **or** this throws [OversizedImageException]. It never returns a path
  /// pointing at a file larger than the cap, so callers can upload the result
  /// without re-checking the size.
  Future<String> compressToMax500Kb(String path) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    const maxBytes = AppConstants.maxImageSizeBytes;

    // Track the smallest result produced across all attempts so a later,
    // higher-quality pass can never "lose" to an earlier smaller one.
    String? best;
    var bestBytes = 1 << 62;

    void consider(XFile? result) {
      if (result == null) return;
      final bytes = File(result.path).lengthSync();
      if (bytes < bestBytes) {
        bestBytes = bytes;
        best = result.path;
      }
    }

    // 1. Quality ramp at full resolution.
    for (int quality = 90; quality >= 30; quality -= 10) {
      // flutter_image_compress will not overwrite an existing destination file
      // (it returns null), so every attempt must use a distinct path —
      // otherwise the loop silently stops after the first pass and oversized
      // images get uploaded unchanged.
      final targetPath = '${dir.path}/audit_${stamp}_q$quality.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        targetPath,
        quality: quality,
      );
      if (result == null) break;
      consider(result);
      if (bestBytes <= maxBytes) return best!;
    }

    // 2. Scale the longest edge down to 1280 px.
    consider(
      await FlutterImageCompress.compressAndGetFile(
        path,
        '${dir.path}/audit_${stamp}_s1280.jpg',
        minWidth: 1280,
        minHeight: 1280,
        quality: 60,
      ),
    );
    if (bestBytes <= maxBytes) return best!;

    // 3. Scale the longest edge down to 800 px.
    consider(
      await FlutterImageCompress.compressAndGetFile(
        path,
        '${dir.path}/audit_${stamp}_s800.jpg',
        minWidth: 800,
        minHeight: 800,
        quality: 50,
      ),
    );
    if (bestBytes <= maxBytes) return best!;

    // Couldn't get under the cap. If the original source is already small
    // enough (e.g. compression was a no-op on an unsupported format), use it;
    // otherwise give up cleanly so the caller can ask for a different photo.
    if (File(path).lengthSync() <= maxBytes) return path;

    throw const OversizedImageException(
      'Image is too large after compression. Please pick a smaller photo.',
    );
  }
}

/// Thrown by [ImageService.compressToMax500Kb] when an image cannot be brought
/// under [AppConstants.maxImageSizeBytes] by quality reduction and downscaling.
/// Callers should surface [message] to the user and let them pick another photo
/// rather than attempting the upload.
class OversizedImageException implements Exception {
  const OversizedImageException(this.message);

  final String message;

  @override
  String toString() => message;
}
