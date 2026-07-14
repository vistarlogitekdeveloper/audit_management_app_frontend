import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_sheet_header.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../../core/widgets/status_pill.dart';
import '../models/audit_question_model.dart';
import '../providers/audit_question_provider.dart';

/// Admin screen to manage the master list of audit points ("questions"):
/// add, edit name/description, drag-to-reorder, and deactivate/reactivate.
/// Reordering and deactivation are safe for historical audits — past sheets
/// snapshot the question name on their own rows.
class AuditQuestionsScreen extends ConsumerStatefulWidget {
  const AuditQuestionsScreen({super.key});

  @override
  ConsumerState<AuditQuestionsScreen> createState() =>
      _AuditQuestionsScreenState();
}

class _AuditQuestionsScreenState extends ConsumerState<AuditQuestionsScreen> {
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(auditQuestionAdminProvider).fetch());
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(auditQuestionAdminProvider);
    final active = provider.activeQuestions;
    final inactive =
        provider.questions.where((q) => !q.isActive).toList();

    return LoadingOverlay(
      isLoading: provider.isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHero(
            title: 'Audit questions',
            subtitle:
                'Add, edit, reorder, and retire the audit points auditors score. '
                'Changes apply to new audits; completed audits keep their original points.',
            icon: Icons.rule_folder_outlined,
            action: FilledButton.icon(
              onPressed: () => _showQuestionSheet(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add question'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          AppPanel(
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${active.length} active point${active.length == 1 ? '' : 's'}'
                    '${inactive.isEmpty ? '' : ' · ${inactive.length} deactivated'}. '
                    'Drag the handle to reorder.',
                    style: AppTextStyles.body13,
                  ),
                ),
                if (inactive.isNotEmpty)
                  Row(
                    children: [
                      Text('Show deactivated',
                          style: AppTextStyles.body12),
                      Switch(
                        value: _showInactive,
                        onChanged: (v) =>
                            setState(() => _showInactive = v),
                      ),
                    ],
                  ),
              ],
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
                        ref.read(auditQuestionAdminProvider).fetch(),
                  ),
                ],
              ),
            )
          else if (active.isEmpty)
            const AppPanel(
                child: EmptyPanel(
                    message: 'No audit questions yet. Add your first point.'))
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: active.length,
              onReorderItem: (oldIndex, newIndex) =>
                  _onReorder(active, oldIndex, newIndex),
              itemBuilder: (context, index) {
                final q = active[index];
                return Padding(
                  key: ValueKey(q.id),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _QuestionCard(
                    question: q,
                    dragIndex: index,
                    onEdit: () => _showQuestionSheet(context, question: q),
                    onDeactivate: () => _deactivate(q),
                  ),
                );
              },
            ),
          if (_showInactive && inactive.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Deactivated', style: AppTextStyles.eyebrow),
            const SizedBox(height: 8),
            ...inactive.map(
              (q) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _QuestionCard(
                  question: q,
                  onEdit: () => _showQuestionSheet(context, question: q),
                  onReactivate: () => _reactivate(q),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onReorder(
    List<AuditQuestionModel> active,
    int oldIndex,
    int newIndex,
  ) async {
    // onReorderItem hands back a newIndex already adjusted for the removal at
    // oldIndex, so we insert at it directly.
    final reordered = [...active];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    try {
      await ref.read(auditQuestionAdminProvider).reorderActive(reordered);
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showErrorSnackbar(context, AppHelpers.readableError(e));
    }
  }

  Future<void> _deactivate(AuditQuestionModel q) async {
    final confirm = await AppHelpers.showConfirmationDialog(
      context: context,
      title: 'Deactivate question',
      message:
          'Remove "${q.name}" from new audits? Completed audits keep it, and '
          'you can reactivate it later.',
      confirmLabel: 'Deactivate',
      confirmColor: AppColors.danger,
    );
    if (!confirm || !mounted) return;
    try {
      await ref.read(auditQuestionAdminProvider).deactivateQuestion(q.id);
      if (!mounted) return;
      AppHelpers.showSuccessSnackbar(context, 'Question deactivated.');
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showErrorSnackbar(context, AppHelpers.readableError(e));
    }
  }

  Future<void> _reactivate(AuditQuestionModel q) async {
    try {
      await ref.read(auditQuestionAdminProvider).reactivateQuestion(q.id);
      if (!mounted) return;
      AppHelpers.showSuccessSnackbar(context, 'Question reactivated.');
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showErrorSnackbar(context, AppHelpers.readableError(e));
    }
  }

  Future<void> _showQuestionSheet(
    BuildContext context, {
    AuditQuestionModel? question,
  }) async {
    Future<void> handleSubmit(
      BuildContext popupContext,
      String name,
      String description,
    ) async {
      try {
        if (question == null) {
          await ref
              .read(auditQuestionAdminProvider)
              .createQuestion(name: name, description: description);
          if (!popupContext.mounted) return;
          AppHelpers.showSuccessSnackbar(popupContext, 'Question added.');
        } else {
          await ref.read(auditQuestionAdminProvider).updateQuestion(
                question.id,
                name: name,
                description: description,
              );
          if (!popupContext.mounted) return;
          AppHelpers.showSuccessSnackbar(popupContext, 'Question updated.');
        }
        if (popupContext.mounted) Navigator.of(popupContext).pop();
      } catch (e) {
        if (!popupContext.mounted) return;
        AppHelpers.showErrorSnackbar(
            popupContext, AppHelpers.readableError(e));
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final media = MediaQuery.sizeOf(dialogContext);
        final isNarrow = media.width < 480;
        final horizontalInset = isNarrow ? 16.0 : 40.0;
        final verticalInset = isNarrow ? 24.0 : 32.0;
        return Dialog(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.line),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: horizontalInset,
            vertical: verticalInset,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: media.height - (verticalInset * 2),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: _QuestionForm(
                existing: question,
                onSubmit: (name, description) =>
                    handleSubmit(dialogContext, name, description),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    this.dragIndex,
    required this.onEdit,
    this.onDeactivate,
    this.onReactivate,
  });

  final AuditQuestionModel question;
  final int? dragIndex;
  final VoidCallback onEdit;
  final VoidCallback? onDeactivate;
  final VoidCallback? onReactivate;

  @override
  Widget build(BuildContext context) {
    final desc = question.description;
    return AppPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dragIndex != null) ...[
            ReorderableDragStartListener(
              index: dragIndex!,
              child: Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Icon(Icons.drag_indicator_rounded,
                    size: 20, color: AppColors.textMuted),
              ),
            ),
          ],
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.28)),
            ),
            child: Text(
              '${question.paramIndex}',
              style: AppTextStyles.medium13
                  .copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(question.name,
                          style: AppTextStyles.medium14),
                    ),
                    if (!question.isActive) ...[
                      const SizedBox(width: 8),
                      const StatusPill(status: 'Inactive'),
                    ],
                  ],
                ),
                if (desc != null && desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(desc, style: AppTextStyles.body12),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'deactivate') onDeactivate?.call();
              if (value == 'reactivate') onReactivate?.call();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (onDeactivate != null)
                const PopupMenuItem(
                    value: 'deactivate', child: Text('Deactivate')),
              if (onReactivate != null)
                const PopupMenuItem(
                    value: 'reactivate', child: Text('Reactivate')),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionForm extends StatefulWidget {
  const _QuestionForm({this.existing, required this.onSubmit});

  final AuditQuestionModel? existing;
  final Future<void> Function(String name, String description) onSubmit;

  @override
  State<_QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<_QuestionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _description =
        TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSheetHeader(
                title: isEdit ? 'Edit question' : 'Add question'),
            const SizedBox(height: 14),
            AppInput(
              label: 'Question / point',
              hint: 'e.g. 5S and hygiene of workplace',
              controller: _name,
              maxLength: 300,
              validator: (v) =>
                  Validators.validateRequired(v, fieldName: 'Question'),
            ),
            const SizedBox(height: 12),
            AppInput(
              label: 'What to check for (optional)',
              hint: 'Describe the audit scope shown under the point.',
              controller: _description,
              maxLines: 4,
              maxLength: 2000,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: isEdit ? 'Save changes' : 'Add question',
                    isLoading: _submitting,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(_name.text.trim(), _description.text.trim());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
