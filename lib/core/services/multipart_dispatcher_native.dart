// Native impl. Off the browser the FormData path through dio works
// fine, and dio's already configured with auth interceptors, so we
// reuse it rather than carrying a second HTTP client just for mobile.

import 'dart:typed_data';

import 'package:dio/dio.dart';

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
  final slash = mimeType.indexOf('/');
  final contentType = slash > 0
      ? DioMediaType(
          mimeType.substring(0, slash),
          mimeType.substring(slash + 1),
        )
      : DioMediaType('image', 'jpeg');

  final form = FormData.fromMap({
    ...fields,
    fileField: MultipartFile.fromBytes(
      bytes,
      filename: filename,
      contentType: contentType,
    ),
  });

  final dio = Dio(BaseOptions(headers: headers));
  final response = await dio.post(
    url,
    data: form,
    options: Options(
      // Anything non-success should NOT throw — the dispatcher layer
      // decides how to surface that to the caller. Throwing here would
      // swallow the response body.
      validateStatus: (_) => true,
    ),
  );

  return MultipartResponse(
    statusCode: response.statusCode ?? 0,
    body: response.data is String
        ? response.data as String
        : response.data?.toString() ?? '',
  );
}
