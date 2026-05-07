import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(apiServiceProvider)),
);

final authProvider = ChangeNotifierProvider<AuthProvider>(
  (ref) => AuthProvider(ref.watch(authServiceProvider)),
);

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service);

  final AuthService _service;

  UserModel? currentUser;
  bool isLoading = false;

  bool get isAuthenticated => currentUser != null;
  String? get token => _service.storedToken;

  Future<void> restoreSession() async {
    currentUser = _service.restoreUser();
    notifyListeners();
  }

  Future<void> login(String email, String password, String role) async {
    isLoading = true;
    notifyListeners();
    try {
      final (_, user) = await _service.login(
        email: email,
        password: password,
        role: role,
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
