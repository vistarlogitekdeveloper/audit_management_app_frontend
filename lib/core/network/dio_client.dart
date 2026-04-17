import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../storage/secure_storage.dart';

part 'dio_client.g.dart';

class DioClient {
  final Dio _dio;
  final SecureStorage _secureStorage;

  DioClient(this._dio, this._secureStorage) {
    _dio.options = BaseOptions(
      baseUrl: 'http://localhost:5000/api/v1',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Handle unauthorized - clear token to force re-login
            await _secureStorage.deleteToken();
            // In a full implementation, you might want to use a global event bus or stream 
            // to notify the router to redirect to the login screen.
          }
          // Simple retry logic on timeout
          if (e.type == DioExceptionType.connectionTimeout || 
              e.type == DioExceptionType.receiveTimeout) {
            // Retry logic could be implemented here or using dio_smart_retry
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}

@riverpod
DioClient dioClient(DioClientRef ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DioClient(Dio(), secureStorage);
}
