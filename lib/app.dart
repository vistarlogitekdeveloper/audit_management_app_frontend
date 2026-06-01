import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_state/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'navigation/app_router.dart';

class VistarAuditApp extends ConsumerStatefulWidget {
  const VistarAuditApp({super.key});

  @override
  ConsumerState<VistarAuditApp> createState() => _VistarAuditAppState();
}

class _VistarAuditAppState extends ConsumerState<VistarAuditApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(authProvider).restoreSession();
      await ref.read(notificationProvider).fetchNotifications();
      await ref.read(connectivityProvider).startMonitoring();
      await ref.read(firebaseMessagingProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    // Session-cache invalidation on login / logout / 401 lives inside
    // AuthProvider itself now — see _invalidateSessionCaches. Doing it
    // there (synchronously before notifyListeners) avoids the race where
    // goRouter's refreshListenable navigates and the new screen mounts
    // on the previous user's cached data before the listener fires.

    return MaterialApp.router(
      title: 'Vistar Audit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
