import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_state/app_providers.dart';
import '../core/constants/app_constants.dart';
import '../features/action_plan/screens/action_plan_screen.dart';
import '../features/audit_plan/screens/create_audit_plan_screen.dart';
import '../features/audit_sheet/screens/audit_sheet_screen.dart';
import '../features/audit_sheet/screens/perform_audit_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/dashboard/screens/admin_dashboard_screen.dart';
import '../features/dashboard/screens/audit_calendar_screen.dart';
import '../features/dashboard/screens/audit_details_screen.dart';
import '../features/dashboard/screens/auditor_dashboard_screen.dart';
import '../features/action_plan_tracker/screens/action_plan_tracker_screen.dart';
import '../features/admin_reports/screens/admin_reports_screen.dart';
import '../features/audit_history/screens/audit_history_screen.dart';
import '../features/cluster/screens/cluster_action_plan_monitor_screen.dart';
import '../features/cluster/screens/cluster_audit_detail_screen.dart';
import '../features/cluster/screens/cluster_dashboard_screen.dart';
import '../features/cluster/screens/cluster_reports_screen.dart';
import '../features/dashboard/screens/owner_dashboard_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/projects/screens/projects_screen.dart';
import '../features/report/screens/audit_report_screen.dart';
import '../features/report/screens/auditor_report_view_screen.dart';
import '../features/report/screens/auditor_reports_screen.dart';
import '../features/review/screens/owner_review_screen.dart';
import '../features/users/screens/users_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import 'main_scaffold.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  final navigatorKey = ref.watch(appNavigatorKeyProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/login',
    refreshListenable: auth,
    redirect: (context, state) {
      final isLoggedIn = auth.isAuthenticated;
      final loggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !loggingIn) return '/login';
      if (isLoggedIn && loggingIn) return auth.homeRouteForRole();

      final role = auth.currentUser?.role;
      final path = state.matchedLocation;
      if (role == AppConstants.roleAdmin) return null;
      if (role == AppConstants.roleAuditor &&
          (path.startsWith('/admin') ||
              path.startsWith('/owner') ||
              path.startsWith('/cluster'))) {
        return '/auditor/dashboard';
      }
      if (role == AppConstants.roleClusterManager) {
        if (path.startsWith('/admin') || path.startsWith('/auditor') ||
            path.startsWith('/owner')) {
          return '/cluster/dashboard';
        }
        return null;
      }
      if (role == AppConstants.roleProjectOwner &&
          (path.startsWith('/admin') ||
              path.startsWith('/auditor') ||
              path.startsWith('/cluster'))) {
        return '/owner/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(
          location: state.uri.toString(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (_, __) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/create-plan',
            builder: (_, __) => const CreateAuditPlanScreen(),
          ),
          GoRoute(
            path: '/admin/calendar',
            builder: (_, __) => const AuditCalendarScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (_, __) => const UsersScreen(),
          ),
          GoRoute(
            path: '/admin/projects',
            builder: (_, __) => const ProjectsScreen(),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (_, __) => const AdminReportsScreen(),
          ),
          GoRoute(
            path: '/auditor/dashboard',
            builder: (_, __) => const AuditorDashboardScreen(),
          ),
          GoRoute(
            path: '/auditor/perform-audit',
            builder: (_, __) => const PerformAuditScreen(),
          ),
          GoRoute(
            path: '/auditor/audit-details/:auditId',
            builder: (_, state) => AuditDetailsScreen(
              auditId: state.pathParameters['auditId']!,
            ),
          ),
          GoRoute(
            path: '/auditor/audit/:auditId',
            builder: (_, state) => AuditSheetScreen(
              auditId: state.pathParameters['auditId']!,
            ),
          ),
          GoRoute(
            path: '/owner/dashboard',
            builder: (_, __) => const OwnerDashboardScreen(),
          ),
          GoRoute(
            path: '/owner/review/:auditId',
            builder: (_, state) => OwnerReviewScreen(
              auditId: state.pathParameters['auditId']!,
            ),
          ),
          GoRoute(
            path: '/owner/action-plan/:auditId',
            builder: (_, state) => ActionPlanScreen(
              auditId: state.pathParameters['auditId']!,
            ),
          ),
          GoRoute(
            path: '/owner/action-plans',
            builder: (_, __) => const ActionPlanTrackerScreen(),
          ),
          GoRoute(
            path: '/cluster/dashboard',
            builder: (_, __) => const ClusterDashboardScreen(),
          ),
          GoRoute(
            path: '/cluster/reports',
            builder: (_, __) => const ClusterReportsScreen(),
          ),
          GoRoute(
            path: '/cluster/audit/:auditId',
            builder: (_, state) => ClusterAuditDetailScreen(
              auditId: state.pathParameters['auditId']!,
            ),
          ),
          GoRoute(
            path: '/cluster/action-plans',
            builder: (_, __) => const ClusterActionPlanMonitorScreen(),
          ),
          GoRoute(
            path: '/auditor/reports',
            builder: (_, __) => const AuditorReportsScreen(),
          ),
          GoRoute(
            // Read-only across-project view of ongoing action plans. Reuses the
            // owner tracker screen — auditors monitor progress; corrective
            // actions are still owned/edited by project owners.
            path: '/auditor/action-plans',
            builder: (_, __) =>
                const ActionPlanTrackerScreen(readOnly: true),
          ),
          GoRoute(
            // Auditor opens an individual plan to approve / reject items and
            // close the audit. Reuses ActionPlanScreen — the screen branches
            // on the current user's role to show the right controls.
            path: '/auditor/action-plan/:auditId',
            builder: (_, state) => ActionPlanScreen(
              auditId: state.pathParameters['auditId']!,
            ),
          ),
          GoRoute(
            path: '/auditor/report/:auditId',
            builder: (_, state) => AuditorReportViewScreen(
              auditId: state.pathParameters['auditId']!,
            ),
          ),
          GoRoute(
            path: '/auditor/history',
            builder: (_, __) => const AuditHistoryScreen(),
          ),
          GoRoute(
            path: '/report/:auditId',
            builder: (_, state) => AuditReportScreen(
              auditId: state.pathParameters['auditId']!,
            ),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
