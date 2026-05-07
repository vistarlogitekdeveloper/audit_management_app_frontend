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

  Future<void> fetchUsers() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      users = await _service.listUsers(
        role: roleFilter.isEmpty ? null : roleFilter,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
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
}
