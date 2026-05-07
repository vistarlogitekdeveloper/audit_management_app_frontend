import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/services/api_service.dart';
import '../features/notifications/providers/notification_provider.dart';

final appNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);

final connectivityProvider = ChangeNotifierProvider<ConnectivityProvider>(
  (ref) => ConnectivityProvider(),
);

final firebaseMessagingProvider =
    ChangeNotifierProvider<FirebaseMessagingController>(
  (ref) => FirebaseMessagingController(
    ref.watch(sharedPreferencesProvider),
    ref.watch(notificationProvider),
    ref.watch(appNavigatorKeyProvider),
  ),
);

class ConnectivityProvider extends ChangeNotifier {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool isOffline = false;

  Future<void> startMonitoring() async {
    final initial = await Connectivity().checkConnectivity();
    isOffline = initial.contains(ConnectivityResult.none);
    notifyListeners();
    _subscription ??=
        Connectivity().onConnectivityChanged.listen((connectivityResults) {
      isOffline = connectivityResults.contains(ConnectivityResult.none);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class FirebaseMessagingController extends ChangeNotifier {
  FirebaseMessagingController(this._prefs, this._notificationProvider, this._navKey);

  final SharedPreferences _prefs;
  final NotificationProvider _notificationProvider;
  final GlobalKey<NavigatorState> _navKey;
  bool initialized = false;

  Future<void> initialize() async {
    if (initialized) return;
    initialized = true;

    final alreadyAsked =
        _prefs.getBool(AppConstants.notificationsAskedKey) ?? false;
    if (!alreadyAsked) {
      await FirebaseMessaging.instance.requestPermission();
      await _prefs.setBool(AppConstants.notificationsAskedKey, true);
    }

    FirebaseMessaging.onMessage.listen((message) async {
      await _notificationProvider.fetchNotifications();
      final navigatorContext = _navKey.currentContext;
      if (navigatorContext != null &&
          navigatorContext.mounted &&
          message.notification != null) {
        ScaffoldMessenger.of(navigatorContext).showSnackBar(
          SnackBar(
            content: Text(
              message.notification!.title ?? message.notification!.body ?? 'New notification',
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = message.data['route']?.toString();
      if (route != null && route.isNotEmpty) {
        final navigatorContext = _navKey.currentContext;
        if (navigatorContext != null && navigatorContext.mounted) {
          GoRouter.of(navigatorContext).go(route);
        }
      }
    });
  }
}
