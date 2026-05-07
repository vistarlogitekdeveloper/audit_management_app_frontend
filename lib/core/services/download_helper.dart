// Public download helper. Conditional imports pick the platform impl —
// the web variant uses a Blob + anchor click; the native variant writes
// to the temp directory and returns the path so callers can show it.
import 'package:flutter/foundation.dart';

import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart'
    if (dart.library.io) 'download_helper_io.dart' as impl;

class DownloadResult {
  const DownloadResult({required this.filename, this.savedPath});
  final String filename;

  /// Native-only: absolute path of the saved file. Null on web (the file is
  /// streamed straight into the browser's downloads folder).
  final String? savedPath;
}

class DownloadHelper {
  /// Triggers a download of [bytes] as [filename] using the right strategy
  /// for the current platform.
  static Future<DownloadResult> save({
    required String filename,
    required Uint8List bytes,
    required String mimeType,
  }) {
    return impl.platformDownload(
      filename: filename,
      bytes: bytes,
      mimeType: mimeType,
    );
  }
}
