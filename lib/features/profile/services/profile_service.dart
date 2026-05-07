import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../auth/models/user_model.dart';

class ProfileService {
  ProfileService(this._api);

  final ApiService _api;

  Future<UserModel> getMe() async {
    final response = await _api.get(ApiConstants.myProfile);
    return UserModel.fromJson(_api.extractObject(response));
  }

  Future<UserModel> updateProfile({
    required String userId,
    required String name,
    required String phone,
  }) async {
    final response = await _api.patch(
      ApiConstants.userById(userId),
      data: {'name': name, 'phone': phone},
    );
    final data = _api.extractObject(response);
    // Backend returns { id, name, phone } from updateUser; preserve email/role
    // by merging onto the current model in the caller.
    return UserModel.fromJson(data);
  }

  Future<void> changePassword({
    required String userId,
    required String newPassword,
  }) async {
    await _api.patch(
      ApiConstants.userById(userId),
      data: {'password': newPassword},
    );
  }
}
