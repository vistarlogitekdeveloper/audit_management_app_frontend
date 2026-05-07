import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/user_model.dart';

class UserService {
  UserService(this._api);

  final ApiService _api;

  Future<List<UserModel>> listUsers({
    String? role,
    bool? isActive,
    int page = 1,
    int limit = 100,
  }) async {
    final query = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (role != null && role.isNotEmpty) query['role'] = role;
    if (isActive != null) query['is_active'] = isActive.toString();
    final response = await _api.get(ApiConstants.users, queryParameters: query);
    return _api
        .extractList(response)
        .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<UserModel> createUser(Map<String, dynamic> payload) async {
    final response = await _api.post(ApiConstants.users, data: payload);
    return UserModel.fromJson(_api.extractObject(response));
  }

  Future<UserModel> updateUser(String id, Map<String, dynamic> payload) async {
    final response =
        await _api.patch(ApiConstants.userById(id), data: payload);
    return UserModel.fromJson(_api.extractObject(response));
  }

  Future<void> deactivateUser(String id) async {
    await _api.delete(ApiConstants.userById(id));
  }
}
