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
  // Use ref.read, not ref.watch: this controller wires one-time FCM stream
  // listeners. Watching notificationProvider recreates the controller every
  // time notifications are fetched (it notifies), re-registering
  // FirebaseMessaging.onMessage listeners without cancelling the old ones —
  // causing duplicate snackbars/fetches.
  (ref) => FirebaseMessagingController(
    ref.read(sharedPreferencesProvider),
    ref.read(notificationProvider),
    ref.read(appNavigatorKeyProvider),
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

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;

  Future<void> initialize() async {
    if (initialized) return;
    initialized = true;

    final alreadyAsked =
        _prefs.getBool(AppConstants.notificationsAskedKey) ?? false;
    if (!alreadyAsked) {
      await FirebaseMessaging.instance.requestPermission();
      await _prefs.setBool(AppConstants.notificationsAskedKey, true);
    }

    _onMessageSub = FirebaseMessaging.onMessage.listen((message) async {
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

    _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = message.data['route']?.toString();
      if (route != null && route.isNotEmpty) {
        final navigatorContext = _navKey.currentContext;
        if (navigatorContext != null && navigatorContext.mounted) {
          GoRouter.of(navigatorContext).go(route);
        }
      }
    });
  }

  @override
  void dispose() {
    _onMessageSub?.cancel();
    _onOpenedSub?.cancel();
    super.dispose();
  }
}
