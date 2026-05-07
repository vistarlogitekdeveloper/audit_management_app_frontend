// Default impl that runs only when neither dart:html nor dart:io is
// available (e.g. during static analysis / unit tests). Throws so a misuse
// surfaces immediately instead of silently doing nothing.
import 'package:flutter/foundation.dart';

import 'download_helper.dart';

Future<DownloadResult> platformDownload({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) async {
  throw UnsupportedError(
    'DownloadHelper is not supported on this platform.',
  );
}
