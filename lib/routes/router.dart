import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/audits/presentation/audit_list_screen.dart';
import '../features/audits/presentation/audit_execution_screen.dart';
import '../features/action_plans/presentation/action_plans_screen.dart';
import '../features/sync/presentation/sync_dashboard_screen.dart';

part 'router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull ?? false;
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !isGoingToLogin) {
        return '/login';
      }

      if (isAuthenticated && isGoingToLogin) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/audits',
        builder: (context, state) => const AuditListScreen(),
        routes: [
          GoRoute(
            path: ':auditId',
            builder: (context, state) {
              final auditId = state.pathParameters['auditId']!;
              return AuditExecutionScreen(auditPlanId: auditId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/action-plans',
        builder: (context, state) => const ActionPlansScreen(),
      ),
      GoRoute(
        path: '/sync-dashboard',
        builder: (context, state) => const SyncDashboardScreen(),
      ),
    ],
  );
}
