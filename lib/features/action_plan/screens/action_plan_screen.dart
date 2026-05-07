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

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(actionPlanProvider);
    final plan = provider.currentPlan;
    final failCount = provider.items.length;

    final auditDate =
        ref.watch(auditSheetProvider).currentSheet?.auditDate ?? DateTime.now();
    final deadline = plan?.dueDate ?? AppDateUtils.actionPlanDeadline(auditDate);
    final remaining = AppDateUtils.daysRemaining(deadline);
    final invalidIndices = _showValidation
        ? provider.validate(planDeadline: deadline)
        : <int>[];

    return LoadingOverlay(
      isLoading: provider.isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHero(
            title: 'Action plan',
            subtitle:
                'Turn failed checkpoints into owned corrective work before the eight-day deadline.',
            icon: Icons.checklist_rounded,
            tone: AppColors.danger,
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
            AppPanel(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 240,
                    child: InfoMetric(
                      label: 'Fail points',
                      value: '$failCount',
                      icon: Icons.error_outline,
                      color: AppColors.danger,
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: InfoMetric(
                      label: 'Submission deadline',
                      value: AppDateUtils.formatDisplay(deadline),
                      icon: Icons.event_busy_outlined,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              provider.items.length,
              (index) => ActionItemWidget(
                key: ValueKey(provider.items[index].id ?? 'new-$index'),
                item: provider.items[index],
                deadline: deadline,
                hasValidationError: invalidIndices.contains(index),
                onChanged: (item) =>
                    ref.read(actionPlanProvider).updateItem(index, item),
              ),
            ),
            const SizedBox(height: 16),
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
            ),
          ],
        ],
      ),
    );
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
              const Icon(Icons.info_outline, color: AppColors.warning),
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
