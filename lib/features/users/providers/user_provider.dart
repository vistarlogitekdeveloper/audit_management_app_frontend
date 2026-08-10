import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider<UserService>(
  (ref) => UserService(ref.watch(apiServiceProvider)),
);

final userProvider = ChangeNotifierProvider<UserProvider>(
  (ref) => UserProvider(ref.watch(userServiceProvider)),
);

class UserProvider extends ChangeNotifier {
  UserProvider(this._service);

  final UserService _service;

  List<UserModel> users = [];
  bool isLoading = false;
  String? error;
  String roleFilter = '';
  String search = '';

  /// Monotonic request id. Rapid filter changes start overlapping fetches;
  /// only the most recent one is allowed to apply its result so a slow
  /// earlier response can't overwrite newer data.
  int _fetchSeq = 0;

  Future<void> fetchUsers() async {
    final seq = ++_fetchSeq;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _service.listUsers(
        role: roleFilter.isEmpty ? null : roleFilter,
      );
      if (seq != _fetchSeq) return;
      users = result;
    } catch (e) {
      if (seq != _fetchSeq) return;
      error = e.toString();
    } finally {
      if (seq == _fetchSeq) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void setRoleFilter(String role) {
    roleFilter = role;
    fetchUsers();
  }

  void setSearch(String value) {
    search = value;
    notifyListeners();
  }

  List<UserModel> get filtered {
    final query = search.trim().toLowerCase();
    if (query.isEmpty) return users;
    return users
        .where((user) =>
            user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query))
        .toList();
  }

  Future<void> createUser(Map<String, dynamic> payload) async {
    final created = await _service.createUser(payload);
    users = [created, ...users];
    notifyListeners();
  }

  Future<void> updateUser(String id, Map<String, dynamic> payload) async {
    final updated = await _service.updateUser(id, payload);
    users = users.map((u) => u.id == id ? updated : u).toList();
    notifyListeners();
  }

  Future<void> deactivateUser(String id) async {
    await _service.deactivateUser(id);
    users = users
        .map((u) => u.id == id ? u.copyWith(isActive: false) : u)
        .toList();
    notifyListeners();
  }

  /// Admin sets a new password for a user. Nothing user-visible changes in the
  /// directory, so we deliberately don't swap the (partial) response into the
  /// list — that would drop email/role/status the update endpoint omits.
  Future<void> changePassword(String id, String password) async {
    await _service.updateUser(id, {'password': password});
  }
}
