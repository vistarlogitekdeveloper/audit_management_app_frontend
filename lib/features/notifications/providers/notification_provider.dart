import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(ref.watch(apiServiceProvider)),
);

final notificationProvider = ChangeNotifierProvider<NotificationProvider>(
  (ref) => NotificationProvider(ref.watch(notificationServiceProvider)),
);

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._service);

  final NotificationService _service;

  List<NotificationModel> notifications = [];
  bool isLoading = false;

  int get unreadCount => notifications.where((item) => !item.isRead).length;

  Future<void> fetchNotifications() async {
    isLoading = true;
    notifyListeners();
    try {
      notifications = await _service.getNotifications();
    } catch (_) {
      notifications = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final original = notifications;
    notifications = notifications
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
    notifyListeners();
    try {
      await _service.markAsRead(id);
    } catch (_) {
      notifications = original;
      notifyListeners();
      rethrow;
    }
  }
}
