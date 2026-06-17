// Analyzer-only fallback. Real platforms route to the _web or _native
// variant via the conditional import in multipart_dispatcher.dart.

import 'package:flutter/foundation.dart';

import 'multipart_dispatcher.dart';

Future<MultipartResponse> platformSend({
  required String url,
  required String fileField,
  required String filename,
  required String mimeType,
  required Uint8List bytes,
  required Map<String, String> fields,
  required Map<String, String> headers,
}) {
  throw UnsupportedError(
    'multipart_dispatcher has no implementation for this platform.',
  );
}
