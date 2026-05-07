import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService(this._apiService);

  final ApiService _apiService;

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _apiService.get(
      ApiConstants.notifications,
      queryParameters: {'page': 1, 'limit': 20},
    );
    final list = _apiService.extractList(response);
    return list
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await _apiService.patch(ApiConstants.markNotificationRead(id));
  }
}
