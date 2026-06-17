// Web impl: build the multipart envelope byte-by-byte and POST it via
// raw XMLHttpRequest. This deliberately uses NEITHER dio nor
// `package:http` nor `html.FormData` — every one of those layers has
// failed against this backend on web for reasons that aren't worth
// debugging when the spec for `multipart/form-data` is 600 lines of
// RFC 7578 and reproducing it by hand fits in 60 lines.

import 'dart:async';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'multipart_dispatcher.dart';

Future<MultipartResponse> platformSend({
  required String url,
  required String fileField,
  required String filename,
  required String mimeType,
  required Uint8List bytes,
  required Map<String, String> fields,
  required Map<String, String> headers,
}) async {
  final formData = html.FormData();

  // Add text fields
  fields.forEach((key, value) {
    formData.append(key, value);
  });

  // Add file field
  final blob = html.Blob(<dynamic>[bytes], mimeType);
  formData.appendBlob(fileField, blob, filename);

  final xhr = html.HttpRequest();
  xhr.open('POST', url);
  xhr.responseType = 'text';

  // Add headers (e.g., Authorization), but filter out Content-Type
  headers.forEach((key, value) {
    if (key.toLowerCase() != 'content-type') {
      xhr.setRequestHeader(key, value);
    }
  });

  final completer = Completer<MultipartResponse>();
  xhr.onLoadEnd.listen((_) {
    if (completer.isCompleted) return;
    completer.complete(
      MultipartResponse(
        statusCode: xhr.status ?? 0,
        body: xhr.responseText ?? '',
      ),
    );
  });
  xhr.onError.listen((_) {
    if (completer.isCompleted) return;
    completer.completeError(
      Exception('Upload network error (status ${xhr.status ?? 'unknown'}).'),
    );
  });

  xhr.send(formData);
  return completer.future;
}
