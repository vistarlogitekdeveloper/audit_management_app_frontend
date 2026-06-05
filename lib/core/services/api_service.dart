import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../utils/helpers.dart';

/// Error thrown by [ApiService] for non-2xx responses / transport failures.
/// Carries the HTTP [statusCode] (null for transport errors) so callers can
/// react to specific cases — e.g. treating 404 as "resource doesn't exist
/// yet" rather than a hard failure.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.isFileTooLarge = false,
  });

  final String message;
  final int? statusCode;

  /// True when the request was rejected because the uploaded file exceeded the
  /// backend's size limit (HTTP 413 or a multer LIMIT_FILE_SIZE error). Set at
  /// construction since it can't be derived from [statusCode] alone.
  final bool isFileTooLarge;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences not initialized'),
);

final apiServiceProvider = Provider<ApiService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final service = ApiService(ref, prefs);
  ref.onDispose(service.dispose);
  return service;
});

class ApiService {
  ApiService(this.ref, this.preferences)
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          // Intentionally no global Content-Type. dio defaults to
          // application/json for POST/PATCH with a Map/JSON body, and for
          // FormData uploads it generates `multipart/form-data; boundary=...`
          // at send time. Forcing a global `application/json` here broke
          // multipart uploads (boundary stripped → backend 400 "File is
          // required") and any attempt to override it per-request triggered
          // dio's "contentType vs content-type header mismatch" assertion.
          headers: {
            'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = preferences.getString(AppConstants.authTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _clearSessionPrefs();
            // Notify the auth layer so it drops the in-memory user and the
            // router redirects to /login — clearing only the token left the
            // app "logged in" with every request failing.
            if (!_unauthorizedController.isClosed) {
              _unauthorizedController.add(null);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Ref ref;
  final SharedPreferences preferences;
  final Dio dio;

  /// Emits when the backend rejects a request with 401 and the local session
  /// has been cleared. The auth layer listens to drive a redirect to /login.
  final _unauthorizedController = StreamController<void>.broadcast();
  Stream<void> get onUnauthorized => _unauthorizedController.stream;

  void _clearSessionPrefs() {
    preferences.remove(AppConstants.authTokenKey);
    preferences.remove(AppConstants.refreshTokenKey);
    preferences.remove(AppConstants.userRoleKey);
    preferences.remove(AppConstants.userIdKey);
    preferences.remove(AppConstants.userNameKey);
    preferences.remove(AppConstants.userEmailKey);
  }

  void dispose() => _unauthorizedController.close();

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<dynamic> post(String path, {Object? data}) async {
    try {
      final response = await dio.post(path, data: data);
      return response.data;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  /// Multipart POST via `package:http` instead of dio. We need this on
  /// Flutter web because dio's BrowserHttpClientAdapter serialises FormData
  /// to a raw byte stream and sends it via XHR with a manually-written
  /// Content-Type header — multer on the backend can't always parse the
  /// resulting body (every upload returns 400 "File is required" / "Image
  /// is required" even though the bytes are on the wire). `http.MultipartRequest`
  /// uses the browser's native FormData wiring on web, which Just Works,
  /// and matches the example the backend team published. Used for native
  /// uploads too so there's a single code path.
  ///
  /// [fileFieldName] is the multipart field the backend reads (e.g. 'image').
  /// Pass exactly one of [filePath] (native) or ([bytes] + [filename]) (web).
  /// [extraFields] are appended as plain form fields next to the file part.
  Future<Map<String, dynamic>> uploadMultipart(
    String path, {
    required String fileFieldName,
    String? filePath,
    Uint8List? bytes,
    String? filename,
    MediaType? contentType,
    Map<String, String> extraFields = const {},
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final request = http.MultipartRequest('POST', uri);
    final token = preferences.getString(AppConstants.authTokenKey);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields.addAll(extraFields);

    if (bytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        fileFieldName,
        bytes,
        filename: filename ?? 'upload',
        contentType: contentType,
      ));
    } else if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath(
        fileFieldName,
        filePath,
        contentType: contentType,
      ));
    } else {
      throw ArgumentError('Provide bytes (web) or filePath (native).');
    }

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      json = <String, dynamic>{};
    }

    if (streamed.statusCode == 401) {
      _clearSessionPrefs();
      if (!_unauthorizedController.isClosed) {
        _unauthorizedController.add(null);
      }
    }

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final message = json['message']?.toString() ??
          'Upload failed (HTTP ${streamed.statusCode}).';
      throw ApiException(
        message: message,
        statusCode: streamed.statusCode,
        isFileTooLarge: streamed.statusCode == 413 ||
            message.toLowerCase().contains('too large'),
      );
    }
    return json;
  }

  Future<dynamic> patch(String path, {Object? data}) async {
    try {
      final response = await dio.patch(path, data: data);
      return response.data;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await dio.delete(path);
      return response.data;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  /// Builds the [ApiException] thrown by every request method, centralising
  /// detection of the backend's upload size rejection so callers get a clear
  /// message instead of a generic failure.
  ApiException _toApiException(DioException error) {
    final tooLarge = _isFileTooLarge(error);
    return ApiException(
      message: tooLarge
          ? 'Image is too large. Please pick a smaller photo.'
          : _mapDioError(error),
      statusCode: error.response?.statusCode,
      isFileTooLarge: tooLarge,
    );
  }

  /// True for an HTTP 413, or any response body mentioning the multer
  /// LIMIT_FILE_SIZE / "File too large" error.
  bool _isFileTooLarge(DioException error) {
    if (error.response?.statusCode == 413) return true;
    final body = (error.response?.data?.toString() ?? '').toLowerCase();
    return body.contains('limit_file_size') || body.contains('file too large');
  }

  String _mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      return 'No internet connection. Please try again.';
    }
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message != null) return message.toString();
    }
    final status = error.response?.statusCode;
    if (status != null) return 'Request failed (HTTP $status).';
    return AppHelpers.readableError(error);
  }

  Map<String, dynamic> extractObject(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
      return response;
    }
    return <String, dynamic>{};
  }

  List<dynamic> extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
    }
    return <dynamic>[];
  }
}
