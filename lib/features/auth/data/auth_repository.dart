import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import 'package:uuid/uuid.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  final Dio _dio;
  final SecureStorage _storage;

  AuthRepository(this._dio, this._storage);

  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'];
        // The backend might return standard { "token": "jwt..." }
        if (token != null) {
          await _storage.saveToken(token);

          // Generate or get device_id for offline sync tracking
          final existingDeviceId = await _storage.getDeviceId();
          if (existingDeviceId == null) {
            await _storage.saveDeviceId(const Uuid().v4());
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Login failed. Please check credentials.');
      }
      throw Exception('An unexpected error occurred during login.');
    }
  }

  Future<void> logout() async {
    await _storage.deleteToken();
  }

  Future<bool> checkAuthStatus() async {
    final token = await _storage.getToken();
    if (token == null) return false;
    
    try {
      final response = await _dio.get('/auth/me');
      return response.statusCode == 200;
    } catch (e) {
      // If network fails (timeout etc), we assume user is authenticated if token exists
      // because offline first! Only 401 should trigger logout.
      if (e is DioException && e.response?.statusCode == 401) {
        await logout();
        return false;
      }
      return true; // Offline but has token
    }
  }
}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(
    ref.watch(dioClientProvider).dio,
    ref.watch(secureStorageProvider),
  );
}
