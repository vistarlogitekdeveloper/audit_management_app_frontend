import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/image_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../audit_sheet/providers/audit_sheet_provider.dart';
import '../../auth/providers/auth_provider.dart';
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
    final sheetProvider = ref.read(auditSheetProvider);
    await sheetProvider.loadSheet(widget.auditId);
    final fallback = (sheetProvider.currentSheet?.parameters ?? [])
        .where((p) => p.result == AppConstants.resultFail)
        .map(
          (p) => ActionItemModel(
            auditParameterId: '',
            parameterName: p.name,
            correctiveAction: '',
            responsiblePerson: '',
            dueDate: AppDateUtils.actionPlanDeadline(
              sheetProvider.currentSheet?.auditDate ?? DateTime.now(),
            ),
            status: AppConstants.apOpen,
            auditorRemark: p.remark,
          ),
        )
        .toList();
    await ref
        .read(actionPlanProvider)
        .loadActionPlan(widget.auditId, fallbackItems: fallback);
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

    final auditDate =
        ref.watch(auditSheetProvider).currentSheet?.auditDate ?? DateTime.now();
    final deadline = plan?.dueDate ?? AppDateUtils.actionPlanDeadline(auditDate);
    final remaining = AppDateUtils.daysRemaining(deadline);
    final invalidIndices = _showValidation && isEditor
        ? provider.validate(planDeadline: deadline)
        : <int>[];

    return LoadingOverlay(
      isLoading: provider.isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHero(
            title: planClosed
                ? 'Action plan (closed)'
                : isAuditor
                    ? 'Review action plan'
                    : 'Action plan',
            subtitle: planClosed
                ? 'Closed by the auditor — no further changes.'
                : isAuditor
                    ? 'Approve each corrective action or reject with a remark. Close the audit once every item is approved.'
                    : 'Turn failed checkpoints into owned corrective work before the eight-day deadline.',
            icon: Icons.checklist_rounded,
            tone: planClosed
                ? AppColors.success
                : (isAuditor ? AppColors.primary : AppColors.danger),
            action: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                remaining < 0
                    ? '${-remaining} days overdue'
                    : '$remaining days remaining',
                style: AppTextStyles.medium14.copyWith(color: AppColors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (plan == null)
            _NoPlanBanner(onAcknowledge: () => context.go('/owner/dashboard'))
          else ...[
            _ReviewSummaryPanel(plan: plan, failCount: failCount),
            const SizedBox(height: 16),
            ...List.generate(
              provider.items.length,
              (index) => ActionItemWidget(
                key: ValueKey(provider.items[index].id ?? 'new-$index'),
                item: provider.items[index],
                deadline: deadline,
                hasValidationError: invalidIndices.contains(index),
                mode: effectiveMode,
                reviewing: provider.isReviewing,
                onChanged: (item) =>
                    ref.read(actionPlanProvider).updateItem(index, item),
                onAddPhoto: effectiveMode == ActionItemMode.edit
                    ? () => _pickAndStagePhoto(index)
                    : null,
                onRemovePhoto: effectiveMode == ActionItemMode.edit
                    ? (photoIndex) => ref
                        .read(actionPlanProvider)
                        .removeItemImageAt(index, photoIndex)
                    : null,
                onReview: isAuditor && !planClosed
                    ? (status, remark) =>
                        _reviewItem(provider.items[index].id, status, remark)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
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

  /// Opens the image picker for action item at [index] and stages the
  /// result. Web reads the bytes (queued for upload as bytes + filename);
  /// native compresses the picked file and queues its path. The actual
  /// network upload is deferred until the owner saves / submits — same
  /// pattern the audit sheet uses, so picking stays snappy and removing
  /// before submit costs no API calls.
  Future<void> _pickAndStagePhoto(int index) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      // Light pre-compress on web matches the audit-sheet picker — the
      // native ImageService path can't run there and uncompressed photos
      // would bloat session memory.
      imageQuality: kIsWeb ? 75 : null,
      maxWidth: kIsWeb ? 1600 : null,
    );
    if (file == null) return;
    final provider = ref.read(actionPlanProvider);

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      if (bytes.length > AppConstants.maxImageSizeBytes) {
        if (!mounted) return;
        AppHelpers.showErrorSnackbar(
          context,
          'Image is too large (over 500 KB). Please pick a smaller photo.',
        );
        return;
      }
      provider.stagePhotoFromBytes(
        index: index,
        previewPath: file.path,
        bytes: bytes,
        filename: file.name,
      );
      return;
    }

    String compressed;
    try {
      compressed =
          await ImageService().compressToMax500Kb(file.path);
    } on OversizedImageException catch (e) {
      if (!mounted) return;
      AppHelpers.showErrorSnackbar(context, e.message);
      return;
    }
    provider.stagePhotoFromPath(index, compressed);
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
    // Dialog returns null when cancelled, '' when submitted without text.
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

/// Header panel: fail count + deadline + per-review counters so the auditor
/// can see at a glance how much review work is left.
class _ReviewSummaryPanel extends StatelessWidget {
  const _ReviewSummaryPanel({required this.plan, required this.failCount});

  final ActionPlanModel plan;
  final int failCount;

  @override
  Widget build(BuildContext context) {
    final approved = plan.items.where((i) => i.isApproved).length;
    final rejected = plan.items.where((i) => i.isRejected).length;
    final pending = plan.items.length - approved - rejected;
    return AppPanel(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 220,
            child: InfoMetric(
              label: 'Fail points',
              value: '$failCount',
              icon: Icons.error_outline,
              color: AppColors.danger,
            ),
          ),
          SizedBox(
            width: 220,
            child: InfoMetric(
              label: 'Submission deadline',
              value: AppDateUtils.formatDisplay(plan.dueDate),
              icon: Icons.event_busy_outlined,
              color: AppColors.warning,
            ),
          ),
          SizedBox(
            width: 160,
            child: InfoMetric(
              label: 'Pending review',
              value: '$pending',
              icon: Icons.hourglass_empty_rounded,
              color: AppColors.warning,
            ),
          ),
          SizedBox(
            width: 160,
            child: InfoMetric(
              label: 'Approved',
              value: '$approved',
              icon: Icons.check_circle_outline,
              color: AppColors.success,
            ),
          ),
          SizedBox(
            width: 160,
            child: InfoMetric(
              label: 'Rejected',
              value: '$rejected',
              icon: Icons.cancel_outlined,
              color: AppColors.danger,
            ),
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
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
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
            controller: _controller,
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
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
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
