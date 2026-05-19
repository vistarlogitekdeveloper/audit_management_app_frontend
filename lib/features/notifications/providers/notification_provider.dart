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

  /// Set when the last fetch failed. Lets the UI distinguish a network error
  /// from a genuinely empty inbox instead of always showing "no notifications".
  String? error;

  int get unreadCount => notifications.where((item) => !item.isRead).length;

  Future<void> fetchNotifications() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      notifications = await _service.getNotifications();
    } catch (e) {
      // Keep the last good list rather than blanking it on a transient error.
      error = e.toString();
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
