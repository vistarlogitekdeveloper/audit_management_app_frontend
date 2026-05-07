import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../../core/widgets/status_pill.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class ClusterDashboardScreen extends ConsumerWidget {
  const ClusterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(clusterDashboardProvider);

    return asyncData.when(
      loading: () => const LoadingState(message: 'Loading cluster overview…'),
      error: (e, _) => ErrorState(
        message: AppHelpers.readableError(e),
        onRetry: () => ref.invalidate(clusterDashboardProvider),
      ),
      data: (data) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHero(
              title: 'Cluster overview',
              subtitle:
                  'Read-only roll-up of audits and action plans across every project in your cluster.',
              icon: Icons.account_tree_outlined,
            ),
            const SizedBox(height: 18),
            _KpiCards(
              auditsThisMonth: data.acknowledged + data.awaitingReview,
              avgPassPercent: data.lastPassPercent,
              openActionPlans: data.actionPlanDue,
              overdueActionPlans: data.actionPlans
                  .where((a) => a.daysRemaining < 0)
                  .length,
            ),
            const SizedBox(height: 14),
            AppPanel(
              title: 'Audits awaiting acknowledgement',
              icon: Icons.rate_review_outlined,
              child: data.auditsAwaiting.isEmpty
                  ? const EmptyPanel(
                      message: 'No audits awaiting acknowledgement.')
                  : Column(
                      children: data.auditsAwaiting
                          .map((audit) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () =>
                                      context.go('/cluster/audit/${audit.id}'),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.greyTint,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(audit.project,
                                                  style:
                                                      AppTextStyles.medium14),
                                              Text(
                                                '${audit.auditor} · ${AppDateUtils.formatDisplay(audit.date)}',
                                                style: AppTextStyles.body12,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${audit.passPercent.toStringAsFixed(0)}%',
                                          style: AppTextStyles.medium14
                                              .copyWith(
                                            color: AppHelpers.passPercentColor(
                                                audit.passPercent),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const StatusPill(status: 'Submitted'),
                                      ],
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 14),
            AppPanel(
              title: 'Open action plans',
              icon: Icons.checklist_rounded,
              child: data.actionPlans.isEmpty
                  ? const EmptyPanel(message: 'No open action plans.')
                  : Column(
                      children: data.actionPlans
                          .map((plan) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () =>
                                      context.go('/cluster/action-plans'),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.greyTint,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(plan.project,
                                                  style:
                                                      AppTextStyles.medium14),
                                              Text(
                                                '${plan.failPoints} fail points · Due ${AppDateUtils.formatDisplay(plan.dueDate)}',
                                                style: AppTextStyles.body12,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          plan.daysRemaining < 0
                                              ? '${-plan.daysRemaining} d overdue'
                                              : '${plan.daysRemaining} d left',
                                          style: AppTextStyles.medium13.copyWith(
                                            color: plan.daysRemaining < 0
                                                ? AppColors.danger
                                                : AppColors.warning,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _KpiCards extends StatelessWidget {
  const _KpiCards({
    required this.auditsThisMonth,
    required this.avgPassPercent,
    required this.openActionPlans,
    required this.overdueActionPlans,
  });

  final int auditsThisMonth;
  final double avgPassPercent;
  final int openActionPlans;
  final int overdueActionPlans;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return GridView.count(
      crossAxisCount: wide ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: wide ? 2.4 : 1.8,
      children: [
        InfoMetric(
          label: 'Audits this month',
          value: '$auditsThisMonth',
          icon: Icons.assignment_outlined,
        ),
        InfoMetric(
          label: 'Average pass %',
          value: '${avgPassPercent.toStringAsFixed(0)}%',
          icon: Icons.trending_up_rounded,
          color: AppHelpers.passPercentColor(avgPassPercent),
        ),
        InfoMetric(
          label: 'Open action plans',
          value: '$openActionPlans',
          icon: Icons.checklist_rounded,
          color: AppColors.warning,
        ),
        InfoMetric(
          label: 'Overdue action plans',
          value: '$overdueActionPlans',
          icon: Icons.warning_amber_rounded,
          color: AppColors.danger,
        ),
      ],
    );
  }
}
