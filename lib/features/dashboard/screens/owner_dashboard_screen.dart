import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/page_chrome.dart';
import '../providers/dashboard_provider.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(ownerDashboardProvider);

    return asyncData.when(
      loading: () => const LoadingState(message: 'Loading dashboard…'),
      error: (e, st) => ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(ownerDashboardProvider),
      ),
      data: (data) {
        final reviews = data.auditsAwaiting.map((a) => _ReviewRow(
          id: a.id,
          project: a.project,
          auditor: a.auditor,
          date: AppDateUtils.formatDisplay(a.date),
          passRate: '${a.passPercent.toStringAsFixed(0)}%',
          failPoints: '${a.failPoints}',
        )).toList();
        
        final actions = data.actionPlans.map((a) => _ActionRow(
          id: a.id,
          project: a.project,
          summary: '${a.failPoints} fail points',
          dueDate: AppDateUtils.formatDisplay(a.dueDate),
          remaining: '${a.daysRemaining} days',
          daysRemaining: a.daysRemaining,
        )).toList();

        final width = MediaQuery.sizeOf(context).width;
        final compact = width < 760;

        final nextReviewId = data.auditsAwaiting.isNotEmpty
            ? data.auditsAwaiting.first.id
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OwnerHero(
              onReview: nextReviewId == null
                  ? null
                  : () => context.go('/owner/review/$nextReviewId'),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: width >= 1000 ? 4 : 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: compact ? 1.2 : 1.65,
              children: [
                _MetricCard(
                  value: '${data.awaitingReview}',
                  label: 'Awaiting review',
                  icon: Icons.rate_review_outlined,
                  color: AppColors.warning,
                  helper: 'Open',
                ),
                _MetricCard(
                  value: '${data.acknowledged}',
                  label: 'Acknowledged',
                  icon: Icons.verified_outlined,
                  color: AppColors.secondary,
                  helper: 'Closed',
                ),
                _MetricCard(
                  value: '${data.actionPlanDue}',
                  label: 'Action plans due',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  helper: 'Urgent',
                ),
                _MetricCard(
                  value: '${data.lastPassPercent.toStringAsFixed(0)}%',
                  label: 'Last pass rate',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.primary,
                  helper: 'Last audit',
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (reviews.isEmpty)
              const _Panel(
                title: 'Audits awaiting acknowledgement',
                icon: Icons.assignment_turned_in_outlined,
                child: EmptyPanel(
                  message:
                      'No audits awaiting acknowledgement right now.',
                ),
              )
            else
              compact
                  ? _ReviewCards(reviews: reviews)
                  : _ReviewTable(reviews: reviews),
            const SizedBox(height: 18),
            _ActionPlanPanel(actions: actions),
          ],
        );
      },
    );
  }
}

class _OwnerHero extends StatelessWidget {
  const _OwnerHero({required this.onReview});

  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review and action hub',
                  style: AppTextStyles.headline22.copyWith(
                    color: AppColors.white,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acknowledge audit outcomes and keep corrective work moving before deadlines slip.',
                  style: AppTextStyles.body14.copyWith(
                    color: AppColors.white.withValues(alpha: 0.82),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onReview,
            icon: const Icon(Icons.rate_review_outlined, size: 18),
            label: const Text('Review next audit'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.helper,
  });

  final String value;
  final String label;
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
              const Spacer(),
              Text(helper, style: AppTextStyles.body11),
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

class _ReviewTable extends StatelessWidget {
  const _ReviewTable({required this.reviews});

  final List<_ReviewRow> reviews;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Audits awaiting acknowledgement',
      icon: Icons.assignment_turned_in_outlined,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.greyTint),
          dataRowMinHeight: 58,
          dataRowMaxHeight: 66,
          columns: const [
            DataColumn(label: Text('Project')),
            DataColumn(label: Text('Auditor')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Pass %')),
            DataColumn(label: Text('Fail points')),
            DataColumn(label: Text('Action')),
          ],
          rows: reviews.map((row) {
            return DataRow(
              cells: [
                DataCell(Text(row.project)),
                DataCell(Text(row.auditor)),
                DataCell(Text(row.date)),
                DataCell(Text(row.passRate)),
                DataCell(Text(row.failPoints)),
                DataCell(
                  AppButton(
                    label: 'Review',
                    icon: Icons.rate_review_outlined,
                    onPressed: () => context.go('/owner/review/${row.id}'),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ReviewCards extends StatelessWidget {
  const _ReviewCards({required this.reviews});

  final List<_ReviewRow> reviews;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Audits awaiting acknowledgement',
      icon: Icons.assignment_turned_in_outlined,
      child: Column(
        children: reviews.map((row) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.greyTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.project, style: AppTextStyles.medium14),
                const SizedBox(height: 6),
                Text('${row.auditor} · ${row.date}', style: AppTextStyles.body12),
                const SizedBox(height: 8),
                Text(
                  '${row.passRate} pass · ${row.failPoints} fail points',
                  style: AppTextStyles.body11.copyWith(color: AppColors.danger),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Review',
                  icon: Icons.rate_review_outlined,
                  isFullWidth: true,
                  onPressed: () => context.go('/owner/review/${row.id}'),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionPlanPanel extends StatelessWidget {
  const _ActionPlanPanel({required this.actions});

  final List<_ActionRow> actions;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Open action plans',
      icon: Icons.checklist_rounded,
      child: Column(
        children: actions.map((item) {
          final urgent = item.isUrgent;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: urgent ? AppColors.redTint : AppColors.greyTint,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: urgent ? AppColors.danger.withValues(alpha: 0.25) : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    urgent ? Icons.priority_high_rounded : Icons.task_alt_rounded,
                    color: urgent ? AppColors.danger : AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.project, style: AppTextStyles.medium14),
                      const SizedBox(height: 4),
                      Text(item.summary, style: AppTextStyles.body12),
                      const SizedBox(height: 4),
                      Text(
                        '${item.dueDate} · ${item.remaining} remaining',
                        style: AppTextStyles.body11.copyWith(
                          color: urgent ? AppColors.danger : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Create Plan',
                  icon: Icons.add_task_rounded,
                  onPressed: () => context.go('/owner/action-plan/${item.id}'),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

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
              Text(title, style: AppTextStyles.title16),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ReviewRow {
  const _ReviewRow({
    required this.id,
    required this.project,
    required this.auditor,
    required this.date,
    required this.passRate,
    required this.failPoints,
  });

  final String id;
  final String project;
  final String auditor;
  final String date;
  final String passRate;
  final String failPoints;
}

class _ActionRow {
  const _ActionRow({
    required this.id,
    required this.project,
    required this.summary,
    required this.dueDate,
    required this.remaining,
    required this.daysRemaining,
  });

  final String id;
  final String project;
  final String summary;
  final String dueDate;
  final String remaining;
  final int daysRemaining;

  /// Urgent when the plan is overdue or due within the next 3 days.
  bool get isUrgent => daysRemaining <= 3;
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
