import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/status_pill.dart';
import '../../audit_plan/providers/audit_plan_provider.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/pass_rate_chart.dart';
import '../widgets/recent_activity_feed.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(adminDashboardProvider);

    return data.when(
      loading: () => const _DashboardLoading(),
      error:
          (error, _) => _DashboardError(
            onRetry: () => ref.invalidate(adminDashboardProvider),
          ),
      data: (dashboard) => _AdminDashboardContent(dashboard: dashboard),
    );
  }
}

class _AdminDashboardContent extends StatelessWidget {
  const _AdminDashboardContent({required this.dashboard});

  final AdminDashboardModel dashboard;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    final stats = dashboard.stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroHeader(
          total: stats.totalPlanned,
          completed: stats.completed,
          pending: stats.pendingReview,
          onCreatePlan: () => context.go('/admin/create-plan'),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: width >= 1100 ? 4 : 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: compact ? 1.25 : 1.65,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _MetricCard(
              label: 'Planned audits',
              value: '${stats.totalPlanned}',
              icon: Icons.event_note_outlined,
              color: AppColors.primary,
              helper: 'Current cycle',
            ),
            _MetricCard(
              label: 'Completed',
              value: '${stats.completed}',
              icon: Icons.verified_outlined,
              color: AppColors.secondary,
              helper: 'Closed audits',
            ),
            _MetricCard(
              label: 'Pending review',
              value: '${stats.pendingReview}',
              icon: Icons.rate_review_outlined,
              color: AppColors.warning,
              helper: 'Needs attention',
            ),
            _MetricCard(
              label: 'Overdue plans',
              value: '${stats.overdueActionPlans}',
              icon: Icons.warning_amber_rounded,
              color: AppColors.danger,
              helper: 'Past due date',
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (width >= 1000)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _UpcomingPanel(
                  items: dashboard.upcomingAudits,
                  projects: dashboard.allProjects,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _PassRatePanel(items: dashboard.clusterPassRates),
                    const SizedBox(height: 18),
                    _ActivityPanel(items: dashboard.recentActivity),
                  ],
                ),
              ),
            ],
          )
        else ...[
          _UpcomingPanel(
            items: dashboard.upcomingAudits,
            projects: dashboard.allProjects,
          ),
          const SizedBox(height: 18),
          _PassRatePanel(items: dashboard.clusterPassRates),
          const SizedBox(height: 18),
          _ActivityPanel(items: dashboard.recentActivity),
        ],
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.total,
    required this.completed,
    required this.pending,
    required this.onCreatePlan,
  });

  final int total;
  final int completed;
  final int pending;
  final VoidCallback onCreatePlan;

  @override
  Widget build(BuildContext context) {
    final rate = total == 0 ? 0 : ((completed / total) * 100).round();

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Admin command center',
          style: AppTextStyles.headline22.copyWith(
            color: AppColors.white,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Plan coverage, review pressure, and action-plan risk in one working view.',
          style: AppTextStyles.body14.copyWith(
            color: AppColors.white.withValues(alpha: 0.82),
            height: 1.45,
          ),
        ),
      ],
    );

    final actions = [
      _HeroSignal(label: 'Completion', value: '$rate%'),
      _HeroSignal(label: 'In review', value: '$pending'),
      IntrinsicWidth(
        child: FilledButton.icon(
          onPressed: onCreatePlan,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create plan'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: titleBlock,
                  ),
                ),
                const SizedBox(width: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions,
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              titleBlock,
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroSignal extends StatelessWidget {
  const _HeroSignal({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.title18.copyWith(color: AppColors.white),
          ),
          Text(
            label,
            style: AppTextStyles.body11.copyWith(
              color: AppColors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.helper,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  helper,
                  style: AppTextStyles.body11,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.statValue),
              const SizedBox(height: 4),
              Text(label, style: AppTextStyles.body13),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingPanel extends ConsumerStatefulWidget {
  const _UpcomingPanel({required this.items, required this.projects});

  final List<UpcomingAudit> items;
  final List<Project> projects;

  @override
  ConsumerState<_UpcomingPanel> createState() => _UpcomingPanelState();
}

class _UpcomingPanelState extends ConsumerState<_UpcomingPanel> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _dateController = TextEditingController();
  UpcomingAudit? _selectedAudit;
  DateTime? _newDate;
  bool _showReschedule = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _UpcomingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedAudit == null) return;
    final stillAvailable = widget.items.any(
      (audit) => audit.id == _selectedAudit!.id,
    );
    if (!stillAvailable) {
      _selectedAudit = null;
      _newDate = null;
      _reasonController.clear();
      _dateController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(auditPlanProvider);

    return _Panel(
      title: 'Upcoming audits',
      icon: Icons.calendar_month_outlined,
      action: AppButton(
        label: _showReschedule ? 'Hide reschedule' : 'Reschedule audit',
        icon:
            _showReschedule
                ? Icons.keyboard_arrow_up_rounded
                : Icons.event_repeat_outlined,
        variant: AppButtonVariant.ghost,
        onPressed:
            widget.items.isEmpty
                ? null
                : () => setState(() => _showReschedule = !_showReschedule),
      ),
      empty: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.items.isEmpty)
            const _EmptyState(message: 'No audits scheduled yet.')
          else
            ...widget.items.take(6).map((audit) {
              final project = widget.projects.firstWhere(
                (p) => p.id == audit.projectId,
                orElse:
                    () => Project(
                      id: audit.projectId,
                      name: 'Unknown Project',
                      location: audit.location,
                      isActive: true,
                    ),
              );

              return _TimelineItem(
                title: project.name,
                subtitle: '${audit.location} - ${audit.status}',
                meta: AppHelpers.formatDate(audit.auditDate),
                status: audit.status,
              );
            }),
          if (_showReschedule && widget.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _RescheduleAuditForm(
                formKey: _formKey,
                audits: widget.items,
                selectedAudit: _selectedAudit,
                selectedDate: _newDate,
                reasonController: _reasonController,
                dateController: _dateController,
                isLoading: provider.isLoading,
                projectLabel: (audit) => _projectFor(audit).name,
                onAuditChanged:
                    (audit) => setState(() => _selectedAudit = audit),
                onDateSelected: (date) => setState(() {
                  _newDate = date;
                  _dateController.text = AppHelpers.formatDate(date);
                }),
                onSubmit: () => _submitReschedule(provider),
              ),
            ),
        ],
      ),
    );
  }

  Project _projectFor(UpcomingAudit audit) {
    return widget.projects.firstWhere(
      (p) => p.id == audit.projectId,
      orElse:
          () => Project(
            id: audit.projectId,
            name: 'Unknown Project',
            location: audit.location,
            isActive: true,
          ),
    );
  }

  Future<void> _submitReschedule(AuditPlanProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.reschedulePlan(
        id: _selectedAudit!.id,
        newDate: _newDate!,
        reason: _reasonController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _showReschedule = false;
        _selectedAudit = null;
        _newDate = null;
        _reasonController.clear();
        _dateController.clear();
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Reschedule notification sent.')),
      );
    } catch (error) {
      if (!mounted) return;
      AppHelpers.showErrorSnackbar(context, AppHelpers.readableError(error));
    }
  }
}

class _RescheduleAuditForm extends StatelessWidget {
  const _RescheduleAuditForm({
    required this.formKey,
    required this.audits,
    required this.selectedAudit,
    required this.selectedDate,
    required this.reasonController,
    required this.dateController,
    required this.isLoading,
    required this.projectLabel,
    required this.onAuditChanged,
    required this.onDateSelected,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final List<UpcomingAudit> audits;
  final UpcomingAudit? selectedAudit;
  final DateTime? selectedDate;
  final TextEditingController reasonController;
  final TextEditingController dateController;
  final bool isLoading;
  final String Function(UpcomingAudit audit) projectLabel;
  final ValueChanged<UpcomingAudit?> onAuditChanged;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.greyTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppDropdown<UpcomingAudit>(
              label: 'Audit',
              value: selectedAudit,
              items:
                  audits
                      .map(
                        (audit) => DropdownMenuItem(
                          value: audit,
                          child: Text(
                            '${projectLabel(audit)} - ${AppHelpers.formatDate(audit.auditDate)}',
                          ),
                        ),
                      )
                      .toList(),
              validator: (value) => value == null ? 'Audit is required' : null,
              onChanged: onAuditChanged,
            ),
            const SizedBox(height: 14),
            AppInput(
              label: 'New date',
              controller: dateController,
              isReadOnly: true,
              validator: (_) => Validators.validateFutureDate(selectedDate),
              suffixIcon: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDate:
                      selectedDate ??
                      DateTime.now().add(const Duration(days: 1)),
                );
                if (selected != null) onDateSelected(selected);
              },
            ),
            const SizedBox(height: 14),
            AppInput(
              label: 'Reason',
              controller: reasonController,
              maxLines: 3,
              validator:
                  (value) =>
                      Validators.validateRequired(value, fieldName: 'Reason'),
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Send reschedule notification',
              icon: Icons.send_rounded,
              variant: AppButtonVariant.ghost,
              isFullWidth: true,
              isLoading: isLoading,
              onPressed: isLoading ? null : onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _PassRatePanel extends StatelessWidget {
  const _PassRatePanel({required this.items});

  final List<ClusterPassRate> items;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Pass rate by cluster',
      icon: Icons.bar_chart_rounded,
      empty: items.isEmpty ? 'Pass-rate data will appear after audits.' : null,
      child: PassRateChart(
        items:
            items
                .map(
                  (item) => {
                    'name': item.clusterName,
                    'percent': (item.passRate * 100).round(),
                  },
                )
                .toList(),
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.items});

  final List<ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Recent activity',
      icon: Icons.bolt_outlined,
      empty: items.isEmpty ? 'No recent activity yet.' : null,
      child: RecentActivityFeed(
        items:
            items.map((item) {
              return {...item.toJson(), 'color': _activityColor(item.type)};
            }).toList(),
      ),
    );
  }

  Color _activityColor(String type) {
    return switch (type.toLowerCase()) {
      'success' || 'completed' || 'approved' => AppColors.secondary,
      'warning' || 'pending' || 'review' => AppColors.warning,
      'danger' || 'overdue' || 'failed' => AppColors.danger,
      _ => AppColors.primary,
    };
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
    this.empty,
    this.action,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? empty;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.title16,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (action != null) ...[const SizedBox(width: 8), action!],
            ],
          ),
          const SizedBox(height: 14),
          if (empty != null) _EmptyState(message: empty!) else child,
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String meta;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.greyTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.medium14),
                const SizedBox(height: 3),
                Text(subtitle, style: AppTextStyles.body12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(meta, style: AppTextStyles.medium12),
              const SizedBox(height: 6),
              StatusPill(status: status),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.greyTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.body13,
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const LoadingState(message: 'Loading dashboard…');
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _panelDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.danger,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text('Dashboard could not load', style: AppTextStyles.title16),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.035),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
}
