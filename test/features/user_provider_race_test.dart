import 'dart:async';

import 'package:audit_management_app_frontend/features/users/models/user_model.dart';
import 'package:audit_management_app_frontend/features/users/providers/user_provider.dart';
import 'package:audit_management_app_frontend/features/users/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user(String id, {String name = ''}) => UserModel(
      id: id,
      name: name.isEmpty ? 'User $id' : name,
      email: '$id@x.com',
      role: 'auditor',
      phone: '',
      isActive: true,
      createdAt: null,
    );

/// Fake whose listUsers returns futures from a queue of Completers, so the
/// test can resolve overlapping fetches out of order deterministically.
class _FakeUserService implements UserService {
  final List<Completer<List<UserModel>>> gates = [];

  @override
  Future<List<UserModel>> listUsers({
    String? role,
    bool? isActive,
    int page = 1,
    int limit = 100,
  }) {
    final c = Completer<List<UserModel>>();
    gates.add(c);
    return c.future;
  }

  @override
  Future<UserModel> createUser(Map<String, dynamic> payload) =>
      throw UnimplementedError();

  @override
  Future<UserModel> updateUser(String id, Map<String, dynamic> payload) =>
      throw UnimplementedError();

  @override
  Future<void> deactivateUser(String id) => throw UnimplementedError();
}

void main() {
  test('#17: a slow earlier fetch does not overwrite a newer one\'s result',
      () async {
    final service = _FakeUserService();
    final provider = UserProvider(service);

    final first = provider.fetchUsers(); // seq 1
    final second = provider.fetchUsers(); // seq 2 (newer)

    expect(service.gates, hasLength(2));

    // Newest request resolves first with its data.
    service.gates[1].complete([_user('new')]);
    await second;
    expect(provider.users.single.id, 'new');

    // The stale, slower request resolves last and must be ignored.
    service.gates[0].complete([_user('stale')]);
    await first;
    expect(provider.users.single.id, 'new');
  });

  test('search filtering is applied client-side over the loaded users',
      () async {
    final service = _FakeUserService();
    final provider = UserProvider(service);

    final f = provider.fetchUsers();
    service.gates.single.complete([
      _user('1', name: 'Alice'),
      _user('2', name: 'Bob'),
    ]);
    await f;

    provider.setSearch('ali');
    expect(provider.filtered.map((u) => u.name), ['Alice']);
  });
}
