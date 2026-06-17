import 'dart:async';
import 'dart:convert' show jsonDecode;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../utils/helpers.dart';
import 'multipart_dispatcher.dart';

/// Error thrown by [ApiService] for non-2xx responses / transport failures.
/// Carries the HTTP [statusCode] (null for transport errors) so callers can
/// react to specific cases — e.g. treating 404 as "resource doesn't exist
/// yet" rather than a hard failure.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

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

  /// Multipart POST. Delegates to [MultipartDispatcher], which uses a
  /// hand-rolled byte-level multipart envelope on web (after dio,
  /// `package:http`, and the browser's own FormData all failed against
  /// this backend's multer pipeline) and dio's FormData on native.
  ///
  /// [fileField] is the form-data key (e.g. `image`). Pass [bytes] +
  /// [filename]. [mimeType] is the wire-level Content-Type for the file
  /// part; falls back to a filename-extension lookup, then `image/jpeg`.
  Future<dynamic> postMultipart(
    String path, {
    required String fileField,
    required List<int> bytes,
    String? filename,
    String? mimeType,
    Map<String, String> fields = const {},
  }) async {
    final effectiveMime = _resolveMimeType(
      mimeType: mimeType,
      filename: filename,
    );
    final token = preferences.getString(AppConstants.authTokenKey);
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final MultipartResponse response;
    try {
      response = await MultipartDispatcher.send(
        url: '${ApiConstants.baseUrl}$path',
        fileField: fileField,
        filename: filename ?? 'upload.jpg',
        mimeType: effectiveMime,
        bytes: Uint8List.fromList(bytes),
        fields: fields,
        headers: headers,
      );
    } catch (error) {
      throw ApiException(message: 'Upload transport error: $error');
    }

    if (!response.isSuccess) {
      String message = 'Request failed (HTTP ${response.statusCode}).';
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {
          // Non-JSON body, keep the generic HTTP message.
        }
      }
      throw ApiException(message: message, statusCode: response.statusCode);
    }

    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  /// Picks the wire-level MIME string for the upload part. Prefers an
  /// explicit [mimeType] from the caller (image_picker's `XFile.mimeType`);
  /// falls back to a filename-extension lookup. Defaults to `image/jpeg`
  /// because every current caller is uploading a photo.
  String _resolveMimeType({String? mimeType, String? filename}) {
    if (mimeType != null && mimeType.contains('/')) return mimeType;
    final ext = filename?.split('.').last.toLowerCase() ?? '';
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  ApiException _toApiException(DioException error) {
    return ApiException(
      message: _mapDioError(error),
      statusCode: error.response?.statusCode,
    );
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
