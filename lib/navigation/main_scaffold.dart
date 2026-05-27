import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_state/app_providers.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/theme_controller.dart';
import '../core/utils/helpers.dart';
import '../core/widgets/brand.dart';
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
    // Watching the theme controller does two jobs here:
    //   1. Rebuilds MainScaffold (sidebar / topbar / nav chrome) so its
    //      AppColors lookups re-resolve under the new brightness.
    //   2. Provides a brightness value to key the routed-page subtree
    //      so Flutter remounts it on toggle — see the KeyedSubtree
    //      below. Without that, Flutter's Element.updateChild short-
    //      circuits on `widget == oldWidget` (same `child` instance
    //      from GoRouter) and the page never re-reads `AppColors.X`.
    //      The trade-off is that the active page loses its in-page
    //      State (scroll position, in-progress form input) on toggle;
    //      navigation / auth / chrome state are preserved.
    final brightness =
        ref.watch(themeControllerProvider).effectiveBrightness;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final items = _navItemsForRole(auth.currentUser?.role ?? '');
    final title = _titleForLocation(location);

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          // Ambient dark canvas + faint S watermark + auroras.
          const Positioned.fill(child: AmbientCanvas()),
          SafeArea(
            // bottom:false because the bottom nav handles its own
            // safe inset.
            bottom: false,
            child: Column(
              children: [
                OfflineBanner(visible: offline),
                Expanded(
                  child: Row(
                    children: [
                      if (!isMobile)
                        _Sidebar(items: items, location: location),
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
                                child: KeyedSubtree(
                                  key: ValueKey(brightness),
                                  child: child,
                                ),
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
          _NavItem('Action Plans', '/auditor/action-plans', Icons.checklist_rounded),
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
        // No owner-scoped reports screen exists; the old '/report/admin'
        // entry routed to ReportScreen(auditId:'admin') and 404'd. Removed
        // until an owner reports view is built (pointing it at the admin
        // reports screen would expose cross-project data).
        return const [
          _NavItem('My Reviews', '/owner/dashboard', Icons.grid_view_rounded),
          _NavItem('Action Plans', '/owner/action-plans', Icons.checklist_rounded),
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
    if (location.contains('/auditor/action-plans')) return 'Action Plans';
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
        location.contains('/cluster/action-plans') ||
        location.contains('/auditor/action-plans')) {
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
        color: AppColors.bgDeep.withValues(alpha: 0.78),
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          if (showMenuHint) ...[
            Container(
              width: 38,
              height: 38,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.line2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset(kSMarkAsset, fit: BoxFit.contain),
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
            child: Icon(Icons.refresh_rounded, size: 20,
                color: AppColors.textPrimary),
          ),
          const SizedBox(width: 10),
          const _ThemeToggleButton(),
          const SizedBox(width: 10),
          _IconSurface(
            tooltip: 'Notifications',
            onTap: () => context.push('/notifications'),
            child: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: Icon(Icons.notifications_none_rounded, size: 20,
                  color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 10),
          if (user != null && MediaQuery.sizeOf(context).width >= 760) ...[
            InkWell(
              borderRadius: BorderRadius.circular(10),
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
            child: Icon(Icons.logout_rounded, size: 19,
                color: AppColors.textPrimary),
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
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
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RibbonAvatar(initials: initials, fallback: color),
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

/// Rounded-square avatar with a ribbon-gradient fill — the design
/// system's signature avatar treatment for chrome rows.
class _RibbonAvatar extends StatelessWidget {
  const _RibbonAvatar({required this.initials, required this.fallback});
  final String initials;
  final Color fallback;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: ribbonGradient(),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.medium12.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
        ),
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
        color: AppColors.bgRaised.withValues(alpha: 0.82),
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: const _BrandLockup(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Row(
              children: [
                Text('WORKSPACE',
                    style: AppTextStyles.eyebrow),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.greenTint,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.28)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Live',
                        style: AppTextStyles.medium12.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
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
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemCount: items.length,
            ),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: InkWell(
                onTap: () => context.go('/profile'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      _RibbonAvatar(
                        initials: user.avatarInitials,
                        fallback: AppHelpers.avatarColorByRole(user.role),
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
                      Icon(Icons.chevron_right_rounded,
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
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.38),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Image.asset(kSMarkAsset, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Render the colourful Vistar wordmark image rather than themed
              // text, so the brand stays legible in dark mode (themed text
              // could blend into the dark sidebar).
              SizedBox(
                height: 18,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    child: Image.asset(kWordmarkAsset),
                  ),
                ),
              ),
              const SizedBox(height: 3),
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
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.24)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Ribbon-gradient active rail (3px on selected, transparent otherwise).
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 3,
              height: 22,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                gradient: selected ? ribbonGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ) : null,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : AppColors.surface2,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.36)
                      : AppColors.line,
                ),
              ),
              child: Icon(
                item.icon,
                size: 17,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.medium13.copyWith(
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
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
      decoration: BoxDecoration(
        color: AppColors.bgRaised,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex.clamp(0, items.length - 1),
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        onDestinationSelected: (index) {
          if (index == selectedIndex) {
            MainScaffold._handlePageRefresh(ref, items[index].route);
          }
          context.go(items[index].route);
        },
        destinations: items.map((item) {
          return NavigationDestination(
            icon: Icon(item.icon, color: AppColors.textMuted),
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

/// Single-tap theme cycler — moves dark → light → system → dark.
/// The icon is the *current* mode's glyph (moon / sun / monitor) so
/// the affordance reads as "what's active" rather than "what's next."
/// Long-press exposes the explicit picker for users who want a
/// specific mode without cycling.
class _ThemeToggleButton extends ConsumerWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(themeControllerProvider);
    final (icon, label) = _glyphFor(controller.mode);

    return Tooltip(
      message: 'Theme — $label (tap to change)',
      child: InkWell(
        onTap: () => controller.cycle(),
        onLongPress: () => _showPicker(context, controller),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Icon(
              icon,
              key: ValueKey(icon.codePoint),
              size: 19,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  (IconData, String) _glyphFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return (Icons.light_mode_rounded, 'Light');
      case ThemeMode.dark:
        return (Icons.dark_mode_rounded, 'Dark');
      case ThemeMode.system:
        return (Icons.brightness_auto_rounded, 'System');
    }
  }

  Future<void> _showPicker(
      BuildContext context, ThemeController controller) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Text('Appearance', style: AppTextStyles.title16),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                      ),
                    ],
                  ),
                ),
                _ThemeChoice(
                  active: controller.mode == ThemeMode.light,
                  icon: Icons.light_mode_rounded,
                  title: 'Light',
                  subtitle: 'Paper-white surfaces, ribbon ink',
                  onTap: () {
                    controller.setMode(ThemeMode.light);
                    Navigator.of(sheetCtx).pop();
                  },
                ),
                const SizedBox(height: 8),
                _ThemeChoice(
                  active: controller.mode == ThemeMode.dark,
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark',
                  subtitle: 'Near-black canvas with the ribbon swoosh',
                  onTap: () {
                    controller.setMode(ThemeMode.dark);
                    Navigator.of(sheetCtx).pop();
                  },
                ),
                const SizedBox(height: 8),
                _ThemeChoice(
                  active: controller.mode == ThemeMode.system,
                  icon: Icons.brightness_auto_rounded,
                  title: 'System',
                  subtitle: 'Follows your device setting',
                  onTap: () {
                    controller.setMode(ThemeMode.system);
                    Navigator.of(sheetCtx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.active,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.10)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.primary.withValues(alpha: 0.36)
                : AppColors.line,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : AppColors.surface3,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active
                      ? AppColors.primary.withValues(alpha: 0.36)
                      : AppColors.line,
                ),
              ),
              child: Icon(icon,
                  size: 19,
                  color: active ? AppColors.primary : AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.medium14.copyWith(
                      color:
                          active ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.body12),
                ],
              ),
            ),
            if (active)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
