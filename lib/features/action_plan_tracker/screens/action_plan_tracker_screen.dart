import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/action_plan_summary.dart';
import '../providers/action_plan_tracker_provider.dart';

class ActionPlanTrackerScreen extends ConsumerStatefulWidget {
  const ActionPlanTrackerScreen({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  ConsumerState<ActionPlanTrackerScreen> createState() =>
      _ActionPlanTrackerScreenState();
}

class _ActionPlanTrackerScreenState
    extends ConsumerState<ActionPlanTrackerScreen> {
  // Keys must be backend ActionPlan.status values (or 'all'); the tracker
  // sends the key verbatim as ?status= (omitted for 'all').
  static const _tabs = [
    ('all', 'All'),
    ('pending', 'Pending'),
    ('submitted', 'In Progress'),
    ('overdue', 'Overdue'),
    ('closed', 'Closed'),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(actionPlanTrackerProvider).fetch());
  }

  /// Wraps each summary in a [_PlanCard] and resolves the deep-link target
  /// from the current user's role: auditors jump into the review screen,
  /// owners into the edit screen, and cluster managers stay on the
  /// read-only audit report. Routing here (rather than inside _PlanCard)
  /// keeps the card a dumb presentation widget.
  List<Widget> _buildCards(List<ActionPlanSummary> plans) {
    final role = AppConstants.normalizeRole(
      ref.watch(authProvider).currentUser?.role,
    );
    String routeFor(ActionPlanSummary plan) {
      if (role == AppConstants.roleAuditor) {
        return '/auditor/action-plan/${plan.auditSheetId}';
      }
      if (widget.readOnly) return '/cluster/audit/${plan.auditPlanId}';
      return '/owner/action-plan/${plan.auditSheetId}';
    }

    return plans
        .map(
          (plan) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PlanCard(
              plan: plan,
              showReviewCounts: role == AppConstants.roleAuditor,
              readOnly: widget.readOnly,
              onOpen: () => context.go(routeFor(plan)),
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(actionPlanTrackerProvider);

    return LoadingOverlay(
      isLoading: provider.isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHero(
            title: widget.readOnly
                ? 'Action plan monitor'
                : 'Action plan tracker',
            subtitle: widget.readOnly
                ? 'Read-only view across the cluster — track progress without editing.'
                : 'Track corrective actions across your projects, sorted by deadline.',
            icon: Icons.fact_check_outlined,
          ),
          const SizedBox(height: 18),
          AppPanel(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tabs.map((entry) {
                final selected = provider.filter == entry.$1;
                return ChoiceChip(
                  label: Text(entry.$2),
                  selected: selected,
                  onSelected: (_) =>
                      ref.read(actionPlanTrackerProvider).setFilter(entry.$1),
                  selectedColor: AppColors.primary.withValues(alpha: 0.12),
                  labelStyle: AppTextStyles.medium13.copyWith(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.32)
                          : AppColors.border,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          if (provider.error != null)
            AppPanel(
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppHelpers.readableError(provider.error!),
                      style: AppTextStyles.body13,
                    ),
                  ),
                  AppButton(
                    label: 'Retry',
                    icon: Icons.refresh_rounded,
                    variant: AppButtonVariant.ghost,
                    onPressed: () =>
                        ref.read(actionPlanTrackerProvider).fetch(),
                  ),
                ],
              ),
            )
          else if (provider.visible.isEmpty)
            AppPanel(
              child: EmptyPanel(
                message: provider.filter == 'all'
                    ? 'No action plans yet. A plan is created automatically '
                        'when a project owner acknowledges an audit that has '
                        'one or more failed parameters.'
                    : 'No action plans match this filter.',
              ),
            )
          else
            ..._buildCards(provider.visible),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.readOnly,
    required this.onOpen,
    this.showReviewCounts = false,
  });

  final ActionPlanSummary plan;
  final bool readOnly;
  final VoidCallback onOpen;

  /// Controls whether the action button reads "Review" (auditor flow)
  /// vs "Edit" / "View" (owner / cluster manager flow). The review-count
  /// chip row (Pending / Approved / Rejected) renders unconditionally —
  /// owners and cluster managers find that summary useful too.
  final bool showReviewCounts;

  @override
  Widget build(BuildContext context) {
    final dueColor = plan.isOverdue
        ? AppColors.danger
        : (plan.daysRemaining <= 3 ? AppColors.warning : AppColors.textPrimary);
    final overallLabel = plan.isClosed
        ? 'Closed'
        : (plan.isOverdue ? 'Overdue' : 'Open');

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(8),
      child: AppPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.projectName, style: AppTextStyles.medium14),
                      const SizedBox(height: 2),
                      Text(
                        '${plan.projectLocation} · Audit ${AppDateUtils.formatDisplay(plan.auditDate)}',
                        style: AppTextStyles.body12,
                      ),
                    ],
                  ),
                ),
                StatusPill(status: overallLabel),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(label: 'Total', value: '${plan.itemsTotal}'),
                _Chip(
                  label: 'Open',
                  value: '${plan.itemsOpen}',
                  color: AppColors.warning,
                ),
                _Chip(
                  label: 'In Progress',
                  value: '${plan.itemsInProgress}',
                  color: AppColors.primary,
                ),
                _Chip(
                  label: 'Closed',
                  value: '${plan.itemsClosed}',
                  color: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(
                  label: 'Pending review',
                  value: '${plan.itemsReviewPending}',
                  color: AppColors.warning,
                ),
                _Chip(
                  label: 'Approved',
                  value: '${plan.itemsReviewApproved}',
                  color: AppColors.success,
                ),
                _Chip(
                  label: 'Rejected',
                  value: '${plan.itemsReviewRejected}',
                  color: AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event_busy_outlined,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Due ${AppDateUtils.formatDisplay(plan.dueDate)}',
                  style: AppTextStyles.body12,
                ),
                const SizedBox(width: 12),
                Text(
                  plan.isOverdue
                      ? '${-plan.daysRemaining} days overdue'
                      : '${plan.daysRemaining} days remaining',
                  style: AppTextStyles.medium12.copyWith(color: dueColor),
                ),
                const Spacer(),
                if (!readOnly || showReviewCounts)
                  TextButton.icon(
                    onPressed: onOpen,
                    icon: Icon(
                      showReviewCounts
                          ? Icons.rate_review_outlined
                          : plan.isClosed
                              ? Icons.visibility_outlined
                              : Icons.edit_outlined,
                      size: 16,
                    ),
                    label: Text(
                      showReviewCounts
                          ? 'Review'
                          : plan.isClosed
                              ? 'View'
                              : 'Edit',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.body11.copyWith(color: tone)),
          const SizedBox(width: 6),
          Text(value,
              style: AppTextStyles.medium13.copyWith(
                color: tone,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}
