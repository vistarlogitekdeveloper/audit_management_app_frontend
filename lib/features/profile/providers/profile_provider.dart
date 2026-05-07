import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>(
  (ref) => ProfileService(ref.watch(apiServiceProvider)),
);

const _prefEmailNotifications = 'pref_email_notifications';
const _prefPushNotifications = 'pref_push_notifications';
const _prefLanguage = 'pref_language';

final profileProvider = ChangeNotifierProvider<ProfileProvider>(
  (ref) => ProfileProvider(
    ref,
    ref.watch(profileServiceProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);

class ProfileProvider extends ChangeNotifier {
  ProfileProvider(this._ref, this._service, this._prefs) {
    emailNotifications = _prefs.getBool(_prefEmailNotifications) ?? true;
    pushNotifications = _prefs.getBool(_prefPushNotifications) ?? true;
    language = _prefs.getString(_prefLanguage) ?? 'English';
  }

  final Ref _ref;
  final ProfileService _service;
  final SharedPreferences _prefs;

  UserModel? user;
  bool isLoading = false;
  String? error;

  // Local-only preferences (no backend column for these yet).
  late bool emailNotifications;
  late bool pushNotifications;
  late String language;

  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      user = await _service.getMe();
      // Mirror name into AuthProvider so the topbar reflects updates.
      final auth = _ref.read(authProvider);
      if (auth.currentUser != null && user != null) {
        auth.currentUser = user;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save({required String name, required String phone}) async {
    final id = user?.id ??
        _prefs.getString(AppConstants.userIdKey) ??
        '';
    if (id.isEmpty) {
      throw StateError('Cannot save profile — current user id is unknown.');
    }
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      // Update returns { id, name, phone } only — preserve email/role locally.
      final updated = await _service.updateProfile(
        userId: id,
        name: name,
        phone: phone,
      );
      user = (user ?? updated).copyWith(name: updated.name, phone: updated.phone);
      // Reflect into auth so the topbar avatar & username refresh.
      final auth = _ref.read(authProvider);
      if (auth.currentUser != null) {
        auth.currentUser = auth.currentUser!.copyWith(
          name: updated.name,
          phone: updated.phone,
        );
      }
      // Update the cached display name in shared_preferences too.
      await _prefs.setString(AppConstants.userNameKey, updated.name);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String newPassword) async {
    final id = user?.id ??
        _prefs.getString(AppConstants.userIdKey) ??
        '';
    if (id.isEmpty) {
      throw StateError('Cannot change password — current user id is unknown.');
    }
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _service.changePassword(userId: id, newPassword: newPassword);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setEmailNotifications(bool value) async {
    emailNotifications = value;
    await _prefs.setBool(_prefEmailNotifications, value);
    notifyListeners();
  }

  Future<void> setPushNotifications(bool value) async {
    pushNotifications = value;
    await _prefs.setBool(_prefPushNotifications, value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    language = value;
    await _prefs.setString(_prefLanguage, value);
    notifyListeners();
  }
}
