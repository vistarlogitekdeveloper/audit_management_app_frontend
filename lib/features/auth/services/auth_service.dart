import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/helpers.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService(this._apiService);

  final ApiService _apiService;

  String? get storedToken =>
      _apiService.preferences.getString(AppConstants.authTokenKey);

  Future<(String, UserModel)> login({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _apiService.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );
    final data = _apiService.extractObject(response);
    final token = data['accessToken']?.toString() ?? '';
    final refreshToken = data['refreshToken']?.toString() ?? '';
    final userJson =
        AppHelpers.asStringMap(data['user']) ?? <String, dynamic>{};
    final responseUser = UserModel.fromJson(userJson);
    final normalizedRole = AppConstants.normalizeRole(
      responseUser.role.isEmpty ? role : responseUser.role,
    );
    final user = UserModel(
      id: responseUser.id,
      name: responseUser.name,
      email: responseUser.email,
      role: normalizedRole,
    );
    await _apiService.preferences.setString(AppConstants.authTokenKey, token);
    await _apiService.preferences.setString(AppConstants.refreshTokenKey, refreshToken);
    await _apiService.preferences.setString(AppConstants.userRoleKey, user.role);
    await _apiService.preferences.setString(AppConstants.userIdKey, user.id);
    await _apiService.preferences.setString(AppConstants.userNameKey, user.name);
    await _apiService.preferences.setString(AppConstants.userEmailKey, user.email);
    return (token, user);
  }

  Future<void> logout() async {
    try {
      await _apiService.post(ApiConstants.logout);
    } catch (_) {
      // Ensure local cleanup even if backend logout fails.
    }
    await clearSession();
  }

  /// Removes every persisted auth key. Used by [logout] and by the 401
  /// handler (which must not hit the network — the token is already invalid).
  Future<void> clearSession() async {
    await _apiService.preferences.remove(AppConstants.authTokenKey);
    await _apiService.preferences.remove(AppConstants.refreshTokenKey);
    await _apiService.preferences.remove(AppConstants.userRoleKey);
    await _apiService.preferences.remove(AppConstants.userIdKey);
    await _apiService.preferences.remove(AppConstants.userNameKey);
    await _apiService.preferences.remove(AppConstants.userEmailKey);
  }

  Future<void> forgotPassword(String email) async {
    await _apiService.post(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );
  }

  Future<String?> refreshToken() async {
    final refreshToken =
        _apiService.preferences.getString(AppConstants.refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) return null;
    final response = await _apiService.post(
      ApiConstants.refreshToken,
      data: {'refreshToken': refreshToken},
    );
    final data = _apiService.extractObject(response);
    final token = data['accessToken']?.toString();
    if (token != null && token.isNotEmpty) {
      await _apiService.preferences.setString(AppConstants.authTokenKey, token);
    }
    return token;
  }

  UserModel? restoreUser() {
    final token = storedToken;
    if (token == null || token.isEmpty) return null;

    final id = _apiService.preferences.getString(AppConstants.userIdKey) ?? '';
    final name = _apiService.preferences.getString(AppConstants.userNameKey) ?? '';
    final email =
        _apiService.preferences.getString(AppConstants.userEmailKey) ?? '';
    final role = AppConstants.normalizeRole(
      _apiService.preferences.getString(AppConstants.userRoleKey),
    );

    if (id.isEmpty || role.isEmpty) return null;
    return UserModel(id: id, name: name, email: email, role: role);
  }
}
