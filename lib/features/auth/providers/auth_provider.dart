import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../../action_plan/providers/action_plan_provider.dart';
import '../../action_plan_tracker/providers/action_plan_tracker_provider.dart';
import '../../audit_plan/providers/audit_plan_provider.dart';
import '../../audit_sheet/providers/audit_sheet_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../projects/providers/project_provider.dart';
import '../../review/providers/review_provider.dart';
import '../../users/providers/user_provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(apiServiceProvider)),
);

final authProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  final provider = AuthProvider(ref, ref.watch(authServiceProvider));
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
  AuthProvider(this._ref, this._service);

  final Ref _ref;
  final AuthService _service;

  UserModel? currentUser;
  bool isLoading = false;

  bool get isAuthenticated => currentUser != null;
  String? get token => _service.storedToken;

  /// Drops every cached session-scoped provider so the next read fetches
  /// fresh state for whichever user is now authenticated (or for the
  /// empty post-logout state). Called synchronously from
  /// [login] / [logout] / [handleUnauthorized] *before* [notifyListeners]
  /// fires — that ordering matters: goRouter's refreshListenable triggers
  /// navigation as soon as we notify, and the new screen's
  /// `ref.watch(someProvider)` runs in the same build pass. If we
  /// invalidated *after* notify, the new screen would mount on the
  /// previous user's cached data and only refresh on a manual reload.
  void _invalidateSessionCaches() {
    _ref.invalidate(adminDashboardProvider);
    _ref.invalidate(auditorDashboardProvider);
    _ref.invalidate(ownerDashboardProvider);
    _ref.invalidate(clusterDashboardProvider);
    _ref.invalidate(notificationProvider);
    _ref.invalidate(auditPlanProvider);
    _ref.invalidate(auditSheetProvider);
    _ref.invalidate(actionPlanProvider);
    _ref.invalidate(actionPlanTrackerProvider);
    _ref.invalidate(reviewProvider);
    _ref.invalidate(projectAdminProvider);
    _ref.invalidate(userProvider);
    _ref.invalidate(profileProvider);
  }

  /// Invoked when a request is rejected with 401. The session prefs are
  /// already cleared by ApiService; here we just drop the in-memory user so
  /// the router redirects to /login. Idempotent — concurrent failing
  /// requests won't trigger a notify storm.
  void handleUnauthorized() {
    if (currentUser == null) return;
    currentUser = null;
    _invalidateSessionCaches();
    notifyListeners();
  }

  Future<void> restoreSession() async {
    currentUser = _service.restoreUser();
    if (currentUser != null) _invalidateSessionCaches();
    notifyListeners();
  }

  /// Logs in, optionally with a chosen [role] for multi-role emails. Returns
  /// the [LoginResult] so the caller can prompt for a role when the backend
  /// asks. Only a real session (single role, or a role picked) sets
  /// [currentUser] and clears caches — a role-selection response leaves the
  /// user unauthenticated so the router stays on /login.
  Future<LoginResult> login(
    String email,
    String password, {
    String? role,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final result = await _service.login(
        email: email,
        password: password,
        role: role,
      );
      if (!result.requiresRoleSelection) {
        currentUser = result.user;
        // Synchronously, before the finally-block's notifyListeners fires
        // the navigation cascade — guarantees the new dashboard mounts on
        // a clean cache rather than the previous user's data.
        _invalidateSessionCaches();
      }
      return result;
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
      _invalidateSessionCaches();
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
