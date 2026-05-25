import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_state/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
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
    // Watching the controller rebuilds the MaterialApp on theme
    // change. Both `theme` and `darkTheme` are constructed each
    // rebuild — that's intentional, because the AppColors getters
    // need to resolve under the active brightness for either theme
    // to be built correctly.
    final themeController = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: 'Vistar Audit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.mode,
      routerConfig: router,
    );
  }
}
