import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_state/app_providers.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/helpers.dart';
import '../core/widgets/offline_banner.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/dashboard/providers/dashboard_provider.dart';
import '../features/audit_plan/providers/audit_plan_provider.dart';
import '../features/notifications/providers/notification_provider.dart';
import '../features/action_plan_tracker/providers/action_plan_tracker_provider.dart';
import '../features/projects/providers/project_provider.dart';
import '../features/users/providers/user_provider.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final notifications = ref.watch(notificationProvider);
    final offline = ref.watch(connectivityProvider).isOffline;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final items = _navItemsForRole(auth.currentUser?.role ?? '');
    final title = _titleForLocation(location);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          OfflineBanner(visible: offline),
          Expanded(
            child: Row(
              children: [
                if (!isMobile) _Sidebar(items: items, location: location),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(
                        title: title,
                        location: location,
                        unreadCount: notifications.unreadCount,
                        showMenuHint: isMobile,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            isMobile ? 14 : 22,
                            18,
                            isMobile ? 14 : 22,
                            24,
                          ),
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? _MobileNav(
              items: items.take(4).toList(),
              selectedIndex: _selectedIndex(items),
            )
          : null,
    );
  }

  int _selectedIndex(List<_NavItem> items) {
    final index = items.indexWhere((item) => location.startsWith(item.route));
    if (index < 0) return 0;
    if (index > 3) return 3;
    return index;
  }

  List<_NavItem> _navItemsForRole(String role) {
    switch (role) {
      case 'Admin':
        return const [
          _NavItem('Dashboard', '/admin/dashboard', Icons.grid_view_rounded),
          _NavItem('Create Audit Plan', '/admin/create-plan', Icons.add_box_outlined),
          _NavItem('Audit Calendar', '/admin/calendar', Icons.calendar_month_outlined),
          _NavItem('Users', '/admin/users', Icons.group_outlined),
          _NavItem('Projects', '/admin/projects', Icons.location_city_outlined),
          _NavItem('Reports & Analytics', '/admin/reports', Icons.insights_outlined),
          _NavItem('Auditor > My Audits', '/auditor/dashboard', Icons.assignment_outlined),
          _NavItem('Auditor > Perform Audit', '/auditor/perform-audit', Icons.play_circle_outline),
          _NavItem('Owner > My Reviews', '/owner/dashboard', Icons.reviews_outlined),
          _NavItem('Owner > Action Plans', '/owner/action-plans', Icons.checklist_rounded),
        ];
      case 'Auditor':
        return const [
          _NavItem('My Audits', '/auditor/dashboard', Icons.grid_view_rounded),
          _NavItem('Perform Audit', '/auditor/perform-audit', Icons.play_circle_outline),
          _NavItem('History', '/auditor/history', Icons.history_rounded),
          _NavItem('Reports', '/auditor/reports', Icons.bar_chart_outlined),
        ];
      case 'ClusterManager':
        return const [
          _NavItem('Cluster Overview', '/cluster/dashboard', Icons.grid_view_rounded),
          _NavItem('Action Plans', '/cluster/action-plans', Icons.checklist_rounded),
          _NavItem('Reports', '/cluster/reports', Icons.bar_chart_outlined),
        ];
      default:
        return const [
          _NavItem('My Reviews', '/owner/dashboard', Icons.grid_view_rounded),
          _NavItem('Action Plans', '/owner/action-plans', Icons.checklist_rounded),
          _NavItem('Reports', '/report/admin', Icons.bar_chart_outlined),
        ];
    }
  }

  String _titleForLocation(String location) {
    if (location.contains('/admin/create-plan')) return 'Create Audit Plan';
    if (location.contains('/admin/calendar')) return 'Audit Calendar';
    if (location.contains('/admin/users')) return 'User Management';
    if (location.contains('/admin/projects')) return 'Project Management';
    if (location.contains('/admin/reports')) return 'Reports & Analytics';
    if (location.contains('/auditor/dashboard')) return 'Auditor Dashboard';
    if (location.contains('/auditor/history')) return 'My Audit History';
    if (location.contains('/auditor/report/')) return 'Audit Report';
    if (location.contains('/owner/dashboard')) return 'Owner Dashboard';
    if (location.contains('/cluster/dashboard')) return 'Cluster Overview';
    if (location.contains('/cluster/reports')) return 'Cluster Reports';
    if (location.contains('/cluster/action-plans')) return 'Cluster Action Plans';
    if (location.contains('/cluster/audit/')) return 'Audit Report';
    if (location.contains('/auditor/perform-audit')) return 'Perform Audit';
    if (location.contains('/auditor/audit/')) return 'Audit Sheet';
    if (location.contains('/owner/review/')) return 'Owner Review';
    if (location.contains('/owner/action-plans')) return 'Action Plans';
    if (location.contains('/owner/action-plan/')) return 'Action Plan';
    if (location.contains('/notifications')) return 'Notifications';
    if (location.contains('/profile')) return 'Profile & settings';
    if (location.contains('/report/')) return 'Audit Report';
    return 'Dashboard';
  }
  static void _handlePageRefresh(WidgetRef ref, String location) {
    if (location.contains('/admin/dashboard')) {
      ref.invalidate(adminDashboardProvider);
    } else if (location.contains('/auditor/dashboard') || location.contains('/auditor/reports') || location.contains('/auditor/perform-audit')) {
      ref.invalidate(auditorDashboardProvider);
    } else if (location.contains('/owner/dashboard')) {
      ref.invalidate(ownerDashboardProvider);
    } else if (location.contains('/cluster/dashboard')) {
      ref.invalidate(clusterDashboardProvider);
    } else if (location.contains('/admin/create-plan') ||
        location.contains('/admin/calendar') ||
        location.contains('/admin/reports')) {
      ref.read(auditPlanProvider).bootstrap();
      if (location.contains('/admin/reports')) {
        ref.invalidate(adminDashboardProvider);
      }
    } else if (location.contains('/admin/users')) {
      ref.read(userProvider).fetchUsers();
    } else if (location.contains('/admin/projects')) {
      ref.read(projectAdminProvider).fetchProjects();
    } else if (location.contains('/owner/action-plans') ||
        location.contains('/cluster/action-plans')) {
      ref.read(actionPlanTrackerProvider).fetch();
    } else if (location.contains('/notifications')) {
      ref.read(notificationProvider).fetchNotifications();
    }
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.title,
    required this.location,
    required this.unreadCount,
    required this.showMenuHint,
  });

  final String title;
  final String location;
  final int unreadCount;
  final bool showMenuHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showMenuHint) ...[
            Container(
              width: 38,
              height: 38,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title18),
                const SizedBox(height: 3),
                Text(
                  _subtitleForLocation(location),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body12,
                ),
              ],
            ),
          ),
          _IconSurface(
            tooltip: 'Refresh data',
            onTap: () => MainScaffold._handlePageRefresh(ref, location),
            child: const Icon(Icons.refresh_rounded, size: 21),
          ),
          const SizedBox(width: 10),
          _IconSurface(
            tooltip: 'Notifications',
            onTap: () => context.push('/notifications'),
            child: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_none_rounded, size: 21),
            ),
          ),
          const SizedBox(width: 10),
          if (user != null && MediaQuery.sizeOf(context).width >= 760) ...[
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.go('/profile'),
              child: _UserChip(
                name: user.name,
                role: AppHelpers.roleLabel(user.role),
                initials: user.avatarInitials,
                color: AppHelpers.avatarColorByRole(user.role),
              ),
            ),
            const SizedBox(width: 10),
          ],
          _IconSurface(
            tooltip: 'Logout',
            onTap: () async {
              final confirm = await AppHelpers.showConfirmationDialog(
                context: context,
                title: 'Logout',
                message: 'Are you sure you want to logout?',
                confirmLabel: 'Logout',
                confirmColor: AppColors.danger,
              );
              if (confirm) {
                await ref.read(authProvider).logout();
                if (context.mounted) context.go('/login');
              }
            },
            child: const Icon(Icons.logout_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  String _subtitleForLocation(String location) {
    if (location.contains('/admin')) return 'Plan, monitor, and close audit work';
    if (location.contains('/auditor')) return 'Execute assigned audits and submit findings';
    if (location.contains('/owner')) return 'Review outcomes and drive corrective actions';
    if (location.contains('/report')) return 'Audit evidence, scoring, and summaries';
    return 'Vistar Audit workspace';
  }
}

class _IconSurface extends StatelessWidget {
  const _IconSurface({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({
    required this.name,
    required this.role,
    required this.initials,
    required this.color,
  });

  final String name;
  final String role;
  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: color,
            child: Text(
              initials,
              style: AppTextStyles.medium12.copyWith(color: AppColors.white),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.medium13,
                ),
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body11,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.items, required this.location});

  final List<_NavItem> items;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;
    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: const Border(right: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.035),
            blurRadius: 20,
            offset: const Offset(10, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const _BrandLockup(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text('Workspace', style: AppTextStyles.medium12),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.greenTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Live',
                    style: AppTextStyles.medium12.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = location.startsWith(item.route);
                return _SidebarItem(
                  item: item,
                  selected: selected,
                  onTap: () {
                    if (selected) {
                      MainScaffold._handlePageRefresh(ref, location);
                    }
                    context.go(item.route);
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemCount: items.length,
            ),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: InkWell(
                onTap: () => context.go('/profile'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.greyTint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppHelpers.avatarColorByRole(user.role),
                        child: Text(
                          user.avatarInitials,
                          style: AppTextStyles.medium12.copyWith(color: AppColors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.medium13,
                            ),
                            Text(
                              AppHelpers.roleLabel(user.role),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body11,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMuted, size: 18),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vistar Audit', style: AppTextStyles.title16),
              Text('Audit command', style: AppTextStyles.body11),
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.blueTint : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary.withValues(alpha: 0.22) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.greyTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon,
                size: 18,
                color: selected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.medium13.copyWith(
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MobileNav extends ConsumerWidget {
  const _MobileNav({
    required this.items,
    required this.selectedIndex,
  });

  final List<_NavItem> items;
  final int selectedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex.clamp(0, items.length - 1),
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.blueTint,
        onDestinationSelected: (index) {
          if (index == selectedIndex) {
            MainScaffold._handlePageRefresh(ref, items[index].route);
          }
          context.go(items[index].route);
        },
        destinations: items.map((item) {
          return NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.icon, color: AppColors.primary),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.route, this.icon);

  final String label;
  final String route;
  final IconData icon;
}
