import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(apiServiceProvider)),
);

final authProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  final provider = AuthProvider(ref.watch(authServiceProvider));
  // When any request 401s, ApiService clears the stored session and emits
  // here so the in-memory user is dropped and the router goes to /login.
  final sub = ref
      .watch(apiServiceProvider)
      .onUnauthorized
      .listen((_) => provider.handleUnauthorized());
  ref.onDispose(sub.cancel);
  return provider;
});

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service);

  final AuthService _service;

  UserModel? currentUser;
  bool isLoading = false;

  bool get isAuthenticated => currentUser != null;
  String? get token => _service.storedToken;

  /// Invoked when a request is rejected with 401. The session prefs are
  /// already cleared by ApiService; here we just drop the in-memory user so
  /// the router redirects to /login. Idempotent — concurrent failing
  /// requests won't trigger a notify storm.
  void handleUnauthorized() {
    if (currentUser == null) return;
    currentUser = null;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    currentUser = _service.restoreUser();
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      final (_, user) = await _service.login(
        email: email,
        password: password,
      );
      currentUser = user;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.logout();
      currentUser = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> forgotPassword(String email) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.forgotPassword(email);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String homeRouteForRole([String? role]) {
    switch (AppConstants.normalizeRole(role ?? currentUser?.role)) {
      case AppConstants.roleAdmin:
        return '/admin/dashboard';
      case AppConstants.roleAuditor:
        return '/auditor/dashboard';
      case AppConstants.roleProjectOwner:
        return '/owner/dashboard';
      case AppConstants.roleClusterManager:
        return '/cluster/dashboard';
      default:
        return '/login';
    }
  }
}
