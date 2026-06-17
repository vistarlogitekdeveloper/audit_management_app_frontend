// Public multipart-upload dispatcher. Conditional imports pick the
// platform impl. The web variant **manually constructs the multipart
// envelope byte-by-byte** and sends it via raw XHR with an explicit
// boundary — no Flutter HTTP library, no browser FormData API in the
// middle. This is the simplest possible HTTP multipart implementation
// that exists; if a backend rejects this, the reason is server-side.
//
// Why this exists (history):
//   1. dio's FormData + BrowserHttpClientAdapter → 400 (backend dropped
//      the file; suspected Blob/contentType mangling)
//   2. package:http MultipartRequest → 400 (same shape, same outcome)
//   3. dart:html FormData + appendBlob → 400 (same)
//   4. dio's FormData per the Productivity Tracker recipe → 400 (same)
//   5. **manual byte construction** ← we're here
//
// The native variant still uses dio (off the browser the FormData path
// works fine and we already have dio set up).

import 'package:flutter/foundation.dart';

import 'multipart_dispatcher_stub.dart'
    if (dart.library.html) 'multipart_dispatcher_web.dart'
    if (dart.library.io) 'multipart_dispatcher_native.dart' as impl;

class MultipartResponse {
  const MultipartResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class MultipartDispatcher {
  /// Sends a single file as multipart/form-data. [fileField] is the form
  /// key (e.g. `image`); [mimeType] is the wire-level Content-Type for
  /// the file part (e.g. `image/jpeg`).
  static Future<MultipartResponse> send({
    required String url,
    required String fileField,
    required String filename,
    required String mimeType,
    required Uint8List bytes,
    required Map<String, String> fields,
    required Map<String, String> headers,
  }) {
    return impl.platformSend(
      url: url,
      fileField: fileField,
      filename: filename,
      mimeType: mimeType,
      bytes: bytes,
      fields: fields,
      headers: headers,
    );
  }
}
