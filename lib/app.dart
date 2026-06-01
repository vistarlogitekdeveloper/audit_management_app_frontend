import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_state/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/action_plan/providers/action_plan_provider.dart';
import 'features/action_plan_tracker/providers/action_plan_tracker_provider.dart';
import 'features/audit_plan/providers/audit_plan_provider.dart';
import 'features/audit_sheet/providers/audit_sheet_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/projects/providers/project_provider.dart';
import 'features/review/providers/review_provider.dart';
import 'features/users/providers/user_provider.dart';
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

    // Watch the auth user id and, whenever it changes, drop every
    // session-scoped data provider so the next read fetches fresh state
    // for the new user. Without this, FutureProviders / ChangeNotifier
    // caches kept the previous user's dashboard rendered until a manual
    // page refresh. The same listener handles login (null → id),
    // logout (id → null), and user switch (idA → idB) — anything where
    // the previously cached data no longer belongs to the active user.
    //
    // app-scoped providers (connectivity, firebase messaging,
    // theme controller, apiService) are deliberately NOT invalidated —
    // those don't carry session data, and tearing them down on every
    // login/logout would lose subscriptions / open sockets unnecessarily.
    ref.listen<String?>(
      authProvider.select((auth) => auth.currentUser?.id),
      (previousId, currentId) {
        if (previousId == currentId) return;
        ref.invalidate(adminDashboardProvider);
        ref.invalidate(auditorDashboardProvider);
        ref.invalidate(ownerDashboardProvider);
        ref.invalidate(clusterDashboardProvider);
        ref.invalidate(notificationProvider);
        ref.invalidate(auditPlanProvider);
        ref.invalidate(auditSheetProvider);
        ref.invalidate(actionPlanProvider);
        ref.invalidate(actionPlanTrackerProvider);
        ref.invalidate(reviewProvider);
        ref.invalidate(projectAdminProvider);
        ref.invalidate(userProvider);
        ref.invalidate(profileProvider);
      },
    );

    return MaterialApp.router(
      title: 'Vistar Audit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
