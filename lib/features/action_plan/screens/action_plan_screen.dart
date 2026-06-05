import 'dart:async' show unawaited;

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
import '../../audit_sheet/providers/audit_sheet_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../users/providers/user_provider.dart';
import '../models/action_plan_model.dart';
import '../providers/action_plan_provider.dart';
import 'action_item_widget.dart';

class ActionPlanScreen extends ConsumerStatefulWidget {
  const ActionPlanScreen({super.key, required this.auditId});

  final String auditId;

  @override
  ConsumerState<ActionPlanScreen> createState() => _ActionPlanScreenState();
}

class _ActionPlanScreenState extends ConsumerState<ActionPlanScreen> {
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    // Fire the users fetch alongside the rest so the "Responsible person"
    // typeahead has something to suggest by the time the form renders.
    // Failures (e.g. 403 for non-admin roles) don't block the screen —
    // the typeahead simply falls back to free-text input.
    unawaited(ref.read(userProvider).fetchUsers());

    // The URL parameter is the action-plan id (the dashboard navigates
    // with `OwnerActionPlan.id`), which `GET /action-plans/:id` accepts
    // directly. `GET /audit-sheets/:auditPlanId` would 404 on that same
    // value, so load the plan first and derive the audit-sheet id from it
    // for the subsequent sheet fetch.
    final actionPlan = ref.read(actionPlanProvider);
    await actionPlan.loadActionPlan(widget.auditId);

    final sheetProvider = ref.read(auditSheetProvider);
    final auditSheetId = actionPlan.currentPlan?.auditSheetId ?? '';
    if (auditSheetId.isNotEmpty) {
      await sheetProvider.loadSheet(auditSheetId);
    }
  }

  /// Owner / Admin can edit items, Auditor reviews them, everyone else (e.g.
  /// Cluster Manager dropping in via a deep link) gets a read-only view.
  ActionItemMode _modeForRole(String role) {
    final normalized = AppConstants.normalizeRole(role);
    if (normalized == AppConstants.roleAuditor) return ActionItemMode.review;
    if (normalized == AppConstants.roleProjectOwner ||
        normalized == AppConstants.roleAdmin) {
      return ActionItemMode.edit;
    }
    return ActionItemMode.readOnly;
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(actionPlanProvider);
    final auth = ref.watch(authProvider);
    final plan = provider.currentPlan;
    final failCount = provider.items.length;

    final mode = _modeForRole(auth.currentUser?.role ?? '');
    final isAuditor = mode == ActionItemMode.review;
    final isEditor = mode == ActionItemMode.edit;
    // Plan-level `status == 'closed'` (or `closedAt` set) is the auditor's
    // explicit close. But the owner is also "done" the moment they've marked
    // every item Closed — at that point they're waiting on the auditor and
    // shouldn't keep editing fields they've already finished. Treat that
    // state as read-only for the editor too; auditors still get review mode
    // so they can approve / close.
    final allItemsOwnerClosed = provider.items.isNotEmpty &&
        provider.items.every(
            (item) => item.status.toLowerCase() == 'closed');
    final planClosed = plan?.isClosed ?? false;
    final ownerDone = isEditor && allItemsOwnerClosed;
    final effectiveMode =
        (planClosed || ownerDone) ? ActionItemMode.readOnly : mode;

    final sheet = ref.watch(auditSheetProvider).currentSheet;

    // All active users surfaced as type-ahead suggestions for the
    // "Responsible person" field. The list is name-only (the dropdown
    // matches on substring); inactive users are filtered so we don't
    // suggest someone who can't actually act on the item.
    final usersWatched = ref.watch(userProvider);
    final responsiblePersonSuggestions = usersWatched.users
        .where((u) => u.isActive && u.name.trim().isNotEmpty)
        .map((u) => u.name)
        .toList();
    // Same trick for the auditor's observation note. The fallback path stores
    // it on `auditorRemark` for unsaved items, but once the backend saves the
    // plan that field is reused for the *review* remark, so we read the
    // original observation straight from the audit sheet every render.
    final observationByName = <String, String>{
      for (final p in sheet?.parameters ?? const [])
        if (p.remark.trim().isNotEmpty) p.name: p.remark.trim(),
    };

    final auditDate = sheet?.auditDate ?? DateTime.now();
    final deadline = plan?.dueDate ?? AppDateUtils.actionPlanDeadline(auditDate);
    final invalidIndices = _showValidation && isEditor
        ? provider.validate(planDeadline: deadline)
        : <int>[];

    // Render items in the same top-to-bottom sequence as the audit sheet
    // (the 24-parameter list in AppConstants). The backend returns items in
    // creation order, which doesn't match the audit flow and leaves the
    // owner scanning around to find the next fail. Sort by parameter rank
    // here without mutating the provider's list — updateItem still uses the
    // original index.
    int rank(String name) {
      final i = AppConstants.auditParameters.indexOf(name);
      return i < 0 ? AppConstants.auditParameters.length : i;
    }

    final displayOrder = List<int>.generate(provider.items.length, (i) => i)
      ..sort((a, b) => rank(provider.items[a].parameterName)
          .compareTo(rank(provider.items[b].parameterName)));

    return LoadingOverlay(
      isLoading: provider.isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderBar(
            mode: mode,
            planClosed: planClosed,
            plan: plan,
            failCount: failCount,
            deadline: deadline,
          ),
          const SizedBox(height: 10),
          if (plan == null)
            _NoPlanBanner(onAcknowledge: () => context.go('/owner/dashboard'))
          else ...[
            ...displayOrder.map((index) {
              final item = provider.items[index];
              return ActionItemWidget(
                key: ValueKey(item.id ?? 'new-$index'),
                item: item,
                deadline: deadline,
                hasValidationError: invalidIndices.contains(index),
                mode: effectiveMode,
                reviewing: provider.isReviewing,
                responsiblePersonSuggestions: responsiblePersonSuggestions,
                auditObservation: observationByName[item.parameterName] ??
                    (item.auditorRemark.isNotEmpty &&
                            item.reviewStatus == 'pending'
                        ? item.auditorRemark
                        : null),
                onChanged: (updated) =>
                    ref.read(actionPlanProvider).updateItem(index, updated),
                onReview: isAuditor && !planClosed
                    ? (status, remark) =>
                        _reviewItem(item.id, status, remark)
                    : null,
              );
            }),
            const SizedBox(height: 10),
            if (planClosed)
              _ClosedBanner(plan: plan)
            else if (isAuditor)
              _AuditorActionBar(
                plan: plan,
                busy: provider.isReviewing,
                onClose: _closePlan,
              )
            // Owner who has marked every item Closed has nothing left to
            // submit — hide the action bar in that interim state so the
            // form reads as locked end-to-end while the auditor reviews.
            else if (isEditor && !ownerDone)
              AppPanel(
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Save Draft',
                        icon: Icons.save_outlined,
                        variant: AppButtonVariant.ghost,
                        onPressed: () => _save(submit: false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Submit Action Plan',
                        icon: Icons.send_rounded,
                        onPressed: () => _save(submit: true),
                      ),
                    ),
                  ],
                ),
              )
            else if (isEditor && ownerDone)
              const _OwnerDoneBanner(),
          ],
        ],
      ),
    );
  }

  Future<void> _reviewItem(
    String? itemId,
    String reviewStatus,
    String remark,
  ) async {
    if (itemId == null || itemId.isEmpty) {
      AppHelpers.showErrorSnackbar(
        context,
        'Item not yet saved on the server — owner must submit the plan first.',
      );
      return;
    }
    try {
      await ref.read(actionPlanProvider).reviewItem(
            itemId: itemId,
            reviewStatus: reviewStatus,
            remark: remark,
          );
      if (!mounted) return;
      AppHelpers.showSuccessSnackbar(
        context,
        reviewStatus == 'approved'
            ? 'Item approved.'
            : 'Item rejected — owner will be notified.',
      );
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showErrorSnackbar(context, AppHelpers.readableError(e));
    }
  }

  Future<void> _closePlan() async {
    final plan = ref.read(actionPlanProvider).currentPlan;
    if (plan == null) return;
    if (!plan.isReviewComplete) {
      AppHelpers.showErrorSnackbar(
        context,
        'All items must be approved before closing the audit.',
      );
      return;
    }
    final remark = await showDialog<String?>(
      context: context,
      builder: (_) => const _CloseAuditDialog(),
    );
    if (remark == null) return;
    try {
      await ref.read(actionPlanProvider).closePlan(remark: remark);
      if (!mounted) return;
      AppHelpers.showSuccessSnackbar(context, 'Audit closed.');
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showErrorSnackbar(context, AppHelpers.readableError(e));
    }
  }

  Future<void> _save({required bool submit}) async {
    final provider = ref.read(actionPlanProvider);
    final plan = provider.currentPlan;
    if (plan == null) {
      AppHelpers.showErrorSnackbar(
        context,
        'Action plan not yet created. Acknowledge the audit first.',
      );
      return;
    }
    setState(() => _showValidation = true);
    final invalid = provider.validate(planDeadline: plan.dueDate);
    if (invalid.isNotEmpty) {
      AppHelpers.showErrorSnackbar(
        context,
        'Please complete every fail point. Due dates must be within ${AppDateUtils.formatDisplay(plan.dueDate)}.',
      );
      return;
    }
    if (submit) {
      final confirm = await AppHelpers.showConfirmationDialog(
        context: context,
        title: 'Submit action plan?',
        message:
            'This will notify Auditor, Cluster Manager, and Management.',
        confirmLabel: 'Submit',
      );
      if (!confirm || !mounted) return;
    }
    try {
      await provider.save();
      if (!mounted) return;
      AppHelpers.showSuccessSnackbar(
        context,
        submit ? 'Action plan submitted.' : 'Action plan draft saved.',
      );
      if (submit) context.go('/owner/dashboard');
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showErrorSnackbar(context, AppHelpers.readableError(e));
    }
  }
}

/// Compact one-card header that replaces the old PageHero + standalone
/// metric panel. Shows title, subtitle, deadline chip, and the per-review
/// counts inline so the whole screen-top fits in ~80 px instead of ~280.
class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.mode,
    required this.planClosed,
    required this.plan,
    required this.failCount,
    required this.deadline,
  });

  final ActionItemMode mode;
  final bool planClosed;
  final ActionPlanModel? plan;
  final int failCount;
  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final isAuditor = mode == ActionItemMode.review;
    final remaining = AppDateUtils.daysRemaining(deadline);
    final tone = planClosed
        ? AppColors.success
        : (isAuditor ? AppColors.primary : AppColors.danger);
    final title = planClosed
        ? 'Action plan (closed)'
        : isAuditor
            ? 'Review action plan'
            : 'Action plan';
    final subtitle = planClosed
        ? 'Closed by the auditor — no further changes.'
        : isAuditor
            ? 'Approve each corrective action or reject with a remark.'
            : 'Turn failed checkpoints into owned corrective work.';

    int approved = 0, rejected = 0, pending = failCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.checklist_rounded, color: tone, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.title16),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.body12),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _DeadlineChip(remaining: remaining),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniStat(
                label: 'Fail points',
                value: '$failCount',
                color: AppColors.danger,
              ),
              _MiniStat(
                label: 'Deadline',
                value: AppDateUtils.formatDisplay(deadline),
                color: AppColors.warning,
              ),
              _MiniStat(
                label: 'Pending',
                value: '$pending',
                color: AppColors.warning,
              ),
              _MiniStat(
                label: 'Approved',
                value: '$approved',
                color: AppColors.success,
              ),
              _MiniStat(
                label: 'Rejected',
                value: '$rejected',
                color: AppColors.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeadlineChip extends StatelessWidget {
  const _DeadlineChip({required this.remaining});
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final overdue = remaining < 0;
    final color = overdue
        ? AppColors.danger
        : (remaining <= 3 ? AppColors.warning : AppColors.textPrimary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        overdue ? '${-remaining}d overdue' : '${remaining}d left',
        style: AppTextStyles.medium12.copyWith(color: color),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.body11.copyWith(color: color)),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTextStyles.medium13
                .copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AuditorActionBar extends StatelessWidget {
  const _AuditorActionBar({
    required this.plan,
    required this.busy,
    required this.onClose,
  });

  final ActionPlanModel plan;
  final bool busy;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ready = plan.isReviewComplete;
    return AppPanel(
      child: Row(
        children: [
          Expanded(
            child: Text(
              ready
                  ? 'All items approved — you can close the audit.'
                  : 'Approve every item before closing the audit.',
              style: AppTextStyles.body13,
            ),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: 'Close Audit',
            icon: Icons.task_alt_rounded,
            onPressed: (busy || !ready) ? null : onClose,
          ),
        ],
      ),
    );
  }
}

class _ClosedBanner extends StatelessWidget {
  const _ClosedBanner({required this.plan});

  final ActionPlanModel plan;

  @override
  Widget build(BuildContext context) {
    final meta = StringBuffer();
    if (plan.closedBy?.name.isNotEmpty == true) meta.write(plan.closedBy!.name);
    if (plan.closedAt != null) {
      if (meta.isNotEmpty) meta.write(' · ');
      meta.write(AppDateUtils.formatDisplay(plan.closedAt!));
    }

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, color: AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Audit closed${meta.isEmpty ? '' : ' by $meta'}',
                  style: AppTextStyles.medium14,
                ),
              ),
            ],
          ),
          if (plan.closeRemark.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(plan.closeRemark, style: AppTextStyles.body13),
          ],
        ],
      ),
    );
  }
}

/// Footer shown to the owner once every item is marked Closed but the
/// auditor hasn't formally closed the plan yet. Mirrors the
/// [_ClosedBanner] visual language so the owner reads it as "done"
/// rather than "still expected to act".
class _OwnerDoneBanner extends StatelessWidget {
  const _OwnerDoneBanner();

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'All items marked Closed — waiting for the auditor to review and close the plan.',
              style: AppTextStyles.medium14,
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseAuditDialog extends StatefulWidget {
  const _CloseAuditDialog();

  @override
  State<_CloseAuditDialog> createState() => _CloseAuditDialogState();
}

class _CloseAuditDialogState extends State<_CloseAuditDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Close audit?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Marks the action plan as closed. The owner can no longer edit items, and a final note (below) is saved to the audit history.',
            style: AppTextStyles.body13,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Closing remark (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Close audit'),
        ),
      ],
    );
  }
}

class _NoPlanBanner extends StatelessWidget {
  const _NoPlanBanner({required this.onAcknowledge});

  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No action plan exists yet for this audit.',
                  style: AppTextStyles.medium14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Action plans are created automatically when a project owner '
            'acknowledges an audit that has fail points.',
            style: AppTextStyles.body13,
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Back to dashboard',
            icon: Icons.arrow_back_rounded,
            variant: AppButtonVariant.ghost,
            onPressed: onAcknowledge,
          ),
        ],
      ),
    );
  }
}
