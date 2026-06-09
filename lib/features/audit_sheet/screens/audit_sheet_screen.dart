import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/audit_sheet_provider.dart';
import 'audit_sheet_row_widget.dart';

class AuditSheetScreen extends ConsumerStatefulWidget {
  const AuditSheetScreen({super.key, required this.auditId});

  final String auditId;

  @override
  ConsumerState<AuditSheetScreen> createState() => _AuditSheetScreenState();
}

class _AuditSheetScreenState extends ConsumerState<AuditSheetScreen> {
  final _scrollController = ScrollController();
  final _controllers = <int, TextEditingController>{};
  bool _showValidation = false;
  Timer? _autoSaveTimer;
  final Set<String> _expandedSections = {'Safety & Work Environment'};

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(auditSheetProvider).loadSheet(widget.auditId),
    );
  }

  // Debounced auto-save: every change kicks the timer; it saves after 10s of inactivity.
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 10), () {
      final provider = ref.read(auditSheetProvider);
      if (provider.hasUnsavedChanges && !provider.isLoading) {
        provider.saveDraft();
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSection(String section) {
    setState(() {
      if (_expandedSections.contains(section)) {
        _expandedSections.remove(section);
      } else {
        _expandedSections.add(section);
      }
    });
  }

  Future<void> _showSubmitSuccessDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.secondary,
        title: 'Audit Submitted Successfully!',
        message:
            'Your audit findings have been recorded. The project owner will be notified for acknowledgment.',
        actions: SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Return to Dashboard',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(auditSheetProvider);
    final sheet = provider.currentSheet;

    // auditSheetProvider is a singleton: until *this* screen's audit has
    // actually been loaded, currentSheet may still hold a previously opened
    // audit's data. Building from it would create remark controllers from the
    // wrong sheet (putIfAbsent never refreshes them afterwards), so wait until
    // the provider's loaded state corresponds to this screen's audit.
    if (sheet == null || !provider.isLoadedFor(widget.auditId)) {
      return const LoadingState(message: 'Loading audit sheet…');
    }

    // Group parameters into sections
    final sections = {
      'Safety & Work Environment':
          sheet.parameters.where((p) => p.index >= 1 && p.index <= 9).toList(),
      'Operations & Documentation':
          sheet.parameters
              .where((p) => p.index >= 10 && p.index <= 16)
              .toList(),
      'Quality, Training & KAIZEN':
          sheet.parameters
              .where((p) => p.index >= 17 && p.index <= 24)
              .toList(),
    };

    final progress =
        sheet.parameters.isEmpty
            ? 0.0
            : provider.auditedCount / sheet.parameters.length;

    // Treat `completed` the same as `acknowledged` here — the rest of the app
    // (audit history, perform-audit list, auditor dashboard) already collapses
    // those two sheet statuses into a single "finished" bucket. Without this,
    // a sheet that lands in `completed` opens in editable mode while the
    // dashboard shows it as done.
    final isAcknowledged =
        sheet.status == 'acknowledged' || sheet.status == 'completed';
    final isSubmitted =
        sheet.status == 'submitted' || sheet.status == 'under_review';

    return PopScope(
      canPop: !provider.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !provider.hasUnsavedChanges) return;
        final leave = await AppHelpers.showConfirmationDialog(
          context: context,
          title: 'Unsaved Changes',
          message:
              'You have unsaved changes. Do you want to save a draft before leaving?',
          confirmLabel: 'Save & Exit',
          cancelLabel: 'Discard',
        );
        if (leave) {
          await provider.saveDraft();
          if (context.mounted) context.pop();
        } else {
          if (context.mounted) context.pop();
        }
      },
      child: LoadingOverlay(
        isLoading: provider.isLoading,
        child: Column(
          children: [
            _AuditHeader(
              projectName: sheet.projectName,
              progress: progress,
              auditedCount: provider.auditedCount,
              totalCount: sheet.parameters.length,
              hasUnsavedChanges: provider.hasUnsavedChanges,
              statusText:
                  isAcknowledged
                      ? 'Acknowedged (Read-only)'
                      : (isSubmitted
                          ? 'Waiting for Acknowledgment'
                          : 'Audit Execution Form'),
            ),
            if (isSubmitted && !isAcknowledged) ...[
              const SizedBox(height: 12),
              _SubmittedEditableBanner(),
            ],
            if (provider.loadError != null) ...[
              const SizedBox(height: 12),
              _SheetLoadErrorBanner(
                message: provider.loadError!,
                onRetry: () =>
                    ref.read(auditSheetProvider).loadSheet(widget.auditId),
              ),
            ],
            const SizedBox(height: 16),
            ListView(
              controller: _scrollController,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _InfoBar(sheet: sheet),
                const SizedBox(height: 16),
                ...sections.entries.map((entry) {
                  final sectionName = entry.key;
                  final items = entry.value;
                  final isExpanded = _expandedSections.contains(sectionName);
                  final completedInSection =
                      items
                          .where((p) => provider.isRowComplete(p.index))
                          .length;

                  return _SectionWrapper(
                    title: sectionName,
                    isExpanded: isExpanded,
                    completedCount: completedInSection,
                    totalCount: items.length,
                    onToggle: () => _toggleSection(sectionName),
                    child: Column(
                      children:
                          items.map((parameter) {
                            final row = provider.rowStates[parameter.index];
                            final controller = _controllers.putIfAbsent(
                              parameter.index,
                              () => TextEditingController(
                                text: row?.remark ?? '',
                              ),
                            );
                            return AuditRowWidget(
                              index: parameter.index,
                              parameterName: parameter.name,
                              selectedResult: row?.result,
                              remarkController: controller,
                              showValidation: _showValidation,
                              isReadOnly: isAcknowledged,
                              onResultChanged: (result) {
                                ref
                                    .read(auditSheetProvider)
                                    .setResult(parameter.index, result);
                                _scheduleAutoSave();
                              },
                              onRemarkChanged: (remark) {
                                ref
                                    .read(auditSheetProvider)
                                    .setRemark(parameter.index, remark);
                                _scheduleAutoSave();
                              },
                            );
                          }).toList(),
                    ),
                  );
                }),
              ],
            ),
            _LiveScoreFooter(
              audited: provider.auditedCount,
              total: sheet.parameters.length,
              pass: provider.passCount,
              fail: provider.failCount,
              passPercent: provider.passPercent,
            ),
            _ActionDock(
              isReadOnly: isAcknowledged,
              isBusy: provider.isLoading,
              submitLabel: isSubmitted ? 'Re-submit Audit' : 'Submit Audit',
              onSave: () async {
                final ok = await provider.saveDraft();
                if (!context.mounted) return;
                if (ok) {
                  AppHelpers.showSuccessSnackbar(
                    context,
                    'Draft saved successfully.',
                  );
                } else {
                  AppHelpers.showErrorSnackbar(
                    context,
                    provider.actionError ??
                        'Could not save draft. Please try again.',
                  );
                }
              },
              onSubmit: () async {
                setState(() => _showValidation = true);
                final incomplete = provider.incompleteRows();
                if (incomplete.isNotEmpty) {
                  // Find first incomplete section and expand it
                  for (final entry in sections.entries) {
                    if (entry.value.any((p) => incomplete.contains(p.index))) {
                      setState(() => _expandedSections.add(entry.key));
                      break;
                    }
                  }
                  AppHelpers.showErrorSnackbar(
                    context,
                    'Please complete all items and mandatory remarks.',
                  );
                  return;
                }

                final confirm = await AppHelpers.showConfirmationDialog(
                  context: context,
                  title: 'Submit Audit?',
                  message:
                      'Are you sure you want to submit this audit? You can edit it until the owner acknowledges.',
                  confirmLabel: 'Submit Now',
                );
                if (!confirm) return;

                final ok = await provider.submitSheet();
                if (!context.mounted) return;
                if (!ok) {
                  AppHelpers.showErrorSnackbar(
                    context,
                    provider.actionError ??
                        'Could not submit the audit. Please try again.',
                  );
                  return;
                }
                ref.invalidate(auditorDashboardProvider);
                await _showSubmitSuccessDialog(context);
                if (context.mounted) context.go('/auditor/dashboard');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmittedEditableBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.edit_note_rounded,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Submitted — still editable. You can keep correcting this audit '
              'until the project owner acknowledges it. Hit "Re-submit Audit" '
              'after changes so the owner sees the latest.',
              style: AppTextStyles.body12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetLoadErrorBanner extends StatelessWidget {
  const _SheetLoadErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_rounded,
              color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Couldn't load the saved audit sheet. Showing a blank "
                  'form — your entries are not synced yet.',
                  style: AppTextStyles.body12,
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTextStyles.body11.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _AuditHeader extends StatelessWidget {
  const _AuditHeader({
    required this.projectName,
    required this.progress,
    required this.auditedCount,
    required this.totalCount,
    required this.hasUnsavedChanges,
    required this.statusText,
  });

  final String projectName;
  final double progress;
  final int auditedCount;
  final int totalCount;
  final bool hasUnsavedChanges;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projectName,
                      style: AppTextStyles.headline22.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: AppTextStyles.body12.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasUnsavedChanges)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.save_as_outlined,
                        size: 14,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Unsaved Changes',
                        style: AppTextStyles.medium12.copyWith(
                          color: AppColors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.white,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$auditedCount/$totalCount completed',
                style: AppTextStyles.medium12.copyWith(color: AppColors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBar extends StatelessWidget {
  const _InfoBar({required this.sheet});
  final dynamic sheet;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _InfoTile(
                label: 'Date',
                value: AppDateUtils.formatDisplay(sheet.auditDate),
                icon: Icons.calendar_today_rounded,
              ),
            ),
            const _InfoDivider(),
            Expanded(
              child: _InfoTile(
                label: 'Location',
                value: sheet.location,
                icon: Icons.location_on_rounded,
              ),
            ),
            const _InfoDivider(),
            Expanded(
              child: _InfoTile(
                label: 'Auditor',
                value: sheet.auditorName.split(' ').first,
                icon: Icons.person_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.border,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.blueTint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.body11),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.medium13,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionWrapper extends StatelessWidget {
  const _SectionWrapper({
    required this.title,
    required this.child,
    required this.isExpanded,
    required this.onToggle,
    required this.completedCount,
    required this.totalCount,
  });

  final String title;
  final Widget child;
  final bool isExpanded;
  final VoidCallback onToggle;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final allDone = completedCount == totalCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(10),
              bottom: Radius.circular(isExpanded ? 0 : 10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: allDone ? AppColors.secondary : AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.title16),
                        const SizedBox(height: 2),
                        Text(
                          '$completedCount of $totalCount completed',
                          style: AppTextStyles.body11.copyWith(
                            color:
                                allDone
                                    ? AppColors.secondary
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (allDone)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.secondary,
                      size: 20,
                    )
                  else
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _LiveScoreFooter extends StatelessWidget {
  const _LiveScoreFooter({
    required this.audited,
    required this.total,
    required this.pass,
    required this.fail,
    required this.passPercent,
  });

  final int audited;
  final int total;
  final int pass;
  final int fail;
  final double passPercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ScoreCell(
            label: 'Audited',
            value: '$audited',
            sub: '/ $total',
            color: AppColors.primary,
          ),
          _ScoreCell(
            label: 'Pass',
            value: '$pass',
            color: AppColors.success,
          ),
          _ScoreCell(
            label: 'Fail',
            value: '$fail',
            color: AppColors.danger,
          ),
          _ScoreCell(
            label: 'Pass %',
            value: '${passPercent.toStringAsFixed(0)}%',
            color: AppHelpers.passPercentColor(passPercent),
          ),
        ],
      ),
    );
  }
}

class _ScoreCell extends StatelessWidget {
  const _ScoreCell({
    required this.label,
    required this.value,
    required this.color,
    this.sub,
  });

  final String label;
  final String value;
  final String? sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(label, style: AppTextStyles.body11),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTextStyles.medium14.copyWith(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (sub != null) ...[
              const SizedBox(width: 2),
              Text(sub!, style: AppTextStyles.body11),
            ],
          ],
        ),
      ],
    );
  }
}

class _ActionDock extends StatelessWidget {
  const _ActionDock({
    required this.onSave,
    required this.onSubmit,
    required this.isReadOnly,
    this.isBusy = false,
    this.submitLabel = 'Submit Audit',
  });
  final VoidCallback onSave;
  final VoidCallback onSubmit;
  final bool isReadOnly;
  final bool isBusy;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child:
          isReadOnly
              ? AppButton(
                label: 'Back to Dashboard',
                icon: Icons.arrow_back,
                isFullWidth: true,
                onPressed: () => context.go('/auditor/dashboard'),
              )
              : Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Save Draft',
                      variant: AppButtonVariant.ghost,
                      isLoading: isBusy,
                      onPressed: isBusy ? null : onSave,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      label: submitLabel,
                      isLoading: isBusy,
                      onPressed: isBusy ? null : onSubmit,
                    ),
                  ),
                ],
              ),
    );
  }
}
