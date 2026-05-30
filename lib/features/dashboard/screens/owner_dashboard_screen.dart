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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

/// Column flex weights, used by both the header row and every data row so
/// they stay aligned without depending on Material's DataTable measuring.
const List<int> _reviewColumnFlex = [3, 3, 2, 1, 2, 2];

class _ReviewTable extends StatelessWidget {
  const _ReviewTable({required this.reviews});

  final List<_ReviewRow> reviews;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Audits awaiting acknowledgement',
      icon: Icons.assignment_turned_in_outlined,
      // Flex-row layout instead of DataTable: each column fills its share of
      // the panel width, so the row stretches to the right edge instead of
      // shrinking to its content. Also avoids DataTable's intrinsic-width
      // pass that was leaving large empty gaps between columns.
      child: Column(
        children: [
          const _ReviewHeaderRow(),
          const SizedBox(height: 6),
          for (var i = 0; i < reviews.length; i++) ...[
            _ReviewDataRow(row: reviews[i]),
            if (i < reviews.length - 1) Divider(color: AppColors.border, height: 1),
          ],
        ],
      ),
    );
  }
}

class _ReviewHeaderRow extends StatelessWidget {
  const _ReviewHeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.medium12.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(flex: _reviewColumnFlex[0], child: Text('PROJECT', style: style)),
          Expanded(flex: _reviewColumnFlex[1], child: Text('AUDITOR', style: style)),
          Expanded(flex: _reviewColumnFlex[2], child: Text('DATE', style: style)),
          Expanded(flex: _reviewColumnFlex[3], child: Text('PASS %', style: style)),
          Expanded(flex: _reviewColumnFlex[4], child: Text('FAIL POINTS', style: style)),
          Expanded(flex: _reviewColumnFlex[5], child: Text('ACTION', style: style)),
        ],
      ),
    );
  }
}

class _ReviewDataRow extends StatelessWidget {
  const _ReviewDataRow({required this.row});

  final _ReviewRow row;

  @override
  Widget build(BuildContext context) {
    final cellStyle = AppTextStyles.body13.copyWith(color: AppColors.textPrimary);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: _reviewColumnFlex[0],
            child: Text(row.project,
                style: cellStyle.copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(flex: _reviewColumnFlex[1], child: Text(row.auditor, style: cellStyle)),
          Expanded(flex: _reviewColumnFlex[2], child: Text(row.date, style: cellStyle)),
          Expanded(flex: _reviewColumnFlex[3], child: Text(row.passRate, style: cellStyle)),
          Expanded(flex: _reviewColumnFlex[4], child: Text(row.failPoints, style: cellStyle)),
          Expanded(
            flex: _reviewColumnFlex[5],
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: 'Review',
                icon: Icons.rate_review_outlined,
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.small,
                onPressed: () => context.go('/owner/review/${row.id}'),
              ),
            ),
          ),
        ],
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
                  variant: AppButtonVariant.ghost,
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
                  variant: AppButtonVariant.ghost,
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
