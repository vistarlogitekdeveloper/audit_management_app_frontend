import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../utils/helpers.dart';

/// Error thrown by [ApiService] for non-2xx responses / transport failures.
/// Carries the HTTP [statusCode] (null for transport errors) so callers can
/// react to specific cases — e.g. treating 404 as "resource doesn't exist
/// yet" rather than a hard failure.
class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode});

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
          headers: {
            'Content-Type': 'application/json',
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
      throw ApiException(
        message: _mapDioError(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  Future<dynamic> post(String path, {Object? data}) async {
    try {
      final response = await dio.post(path, data: data);
      return response.data;
    } on DioException catch (error) {
      throw ApiException(
        message: _mapDioError(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  /// Multipart POST (file upload). [formData] should be a Dio [FormData];
  /// the content type (incl. boundary) is set explicitly so the global
  /// JSON default header doesn't break the request.
  Future<dynamic> upload(String path, {required FormData formData}) async {
    try {
      final response = await dio.post(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.data;
    } on DioException catch (error) {
      throw ApiException(
        message: _mapDioError(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  Future<dynamic> patch(String path, {Object? data}) async {
    try {
      final response = await dio.patch(path, data: data);
      return response.data;
    } on DioException catch (error) {
      throw ApiException(
        message: _mapDioError(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await dio.delete(path);
      return response.data;
    } on DioException catch (error) {
      throw ApiException(
        message: _mapDioError(error),
        statusCode: error.response?.statusCode,
      );
    }
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
