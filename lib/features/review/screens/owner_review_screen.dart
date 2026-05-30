import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../../core/widgets/status_pill.dart';
import '../../action_plan_tracker/providers/action_plan_tracker_provider.dart';
import '../../audit_sheet/providers/audit_sheet_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/review_provider.dart';

class OwnerReviewScreen extends ConsumerStatefulWidget {
  const OwnerReviewScreen({super.key, required this.auditId});

  final String auditId;

  @override
  ConsumerState<OwnerReviewScreen> createState() => _OwnerReviewScreenState();
}

class _OwnerReviewScreenState extends ConsumerState<OwnerReviewScreen> {
  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(auditSheetProvider).loadSheet(widget.auditId),
    );
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheet = ref.watch(auditSheetProvider).currentSheet;
    final review = ref.watch(reviewProvider);

    if (sheet == null) return const Center(child: CircularProgressIndicator());

    final pass = sheet.parameters.where((item) => item.result == 'pass').length;
    final fail = sheet.parameters.where((item) => item.result == 'fail').length;
    final wide = MediaQuery.sizeOf(context).width > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHero(
          title: 'Owner review',
          subtitle:
              'Review submitted evidence, acknowledge the report, and trigger corrective action when needed.',
          icon: Icons.rate_review_outlined,
          tone: AppColors.warning,
          action: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Pass $pass - Fail $fail',
              style: AppTextStyles.medium14.copyWith(color: AppColors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppPanel(
          child: GridView.count(
            crossAxisCount: wide ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: wide ? 3 : 2.1,
            children: [
              InfoMetric(
                label: 'Project',
                value: sheet.projectName,
                icon: Icons.apartment_rounded,
              ),
              InfoMetric(
                label: 'Auditor',
                value: sheet.auditorName,
                icon: Icons.person_outline,
                color: AppColors.secondary,
              ),
              InfoMetric(
                label: 'Audit date',
                value: AppDateUtils.formatDisplay(sheet.auditDate),
                icon: Icons.event_outlined,
                color: AppColors.warning,
              ),
              InfoMetric(
                label: 'Result summary',
                value: 'Pass: $pass - Fail: $fail',
                icon: Icons.insights_rounded,
                color: AppColors.purple,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppPanel(
          title: 'Parameter review',
          icon: Icons.checklist_rounded,
          child: Column(
            children: sheet.parameters.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.greyTint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.index}. ${item.name}',
                            style: AppTextStyles.medium14,
                          ),
                        ),
                        StatusPill(status: item.result ?? 'Pending'),
                      ],
                    ),
                    if (item.remark.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(item.remark, style: AppTextStyles.body12),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        AppPanel(
          title: 'Owner remarks',
          icon: Icons.notes_rounded,
          child: TextField(
            controller: _remarksController,
            maxLines: 3,
            onChanged: ref.read(reviewProvider).setOwnerRemarks,
            decoration: const InputDecoration(
              labelText: 'Add your remarks (optional)',
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppPanel(
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Back',
                  icon: Icons.arrow_back_rounded,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Acknowledge Audit',
                  icon: Icons.verified_outlined,
                  isLoading: review.isLoading,
                  onPressed: () async {
                    final confirm = await AppHelpers.showConfirmationDialog(
                      context: context,
                      title: 'Acknowledge this audit?',
                      message: 'This action cannot be undone.',
                      confirmLabel: 'Acknowledge',
                      confirmColor: AppColors.success,
                    );
                    if (!confirm) return;
                    try {
                      final result = await ref
                          .read(reviewProvider)
                          .acknowledge(widget.auditId);
                      // Server is authoritative now: the audit just moved
                      // out of `awaitingAcknowledgement`. Without this,
                      // FutureProvider keeps its old snapshot and the
                      // dashboards keep showing the audit in the "to be
                      // acknowledged" list. Invalidating every role's
                      // dashboard covers the same-session case for both
                      // owner and cluster manager; cross-session, the
                      // next dashboard fetch picks up the new state.
                      // Also refresh the action-plan tracker because an
                      // ack with fail points auto-creates a plan.
                      ref.invalidate(ownerDashboardProvider);
                      ref.invalidate(clusterDashboardProvider);
                      ref.invalidate(auditorDashboardProvider);
                      ref.invalidate(adminDashboardProvider);
                      ref.read(actionPlanTrackerProvider).fetch();
                      if (!context.mounted) return;
                      AppHelpers.showSuccessSnackbar(
                        context,
                        'Audit acknowledged. Report sent to stakeholders.',
                      );
                      // Trust the backend's response over the local count —
                      // it is authoritative for whether an action plan was
                      // auto-created.
                      if (result.hasFailPoints) {
                        context.go('/owner/action-plan/${widget.auditId}');
                      } else {
                        context.go('/owner/dashboard');
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      AppHelpers.showErrorSnackbar(
                        context,
                        AppHelpers.readableError(e),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
