import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../admin_reports/services/report_export_client.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class AuditorReportsScreen extends ConsumerStatefulWidget {
  const AuditorReportsScreen({super.key});

  @override
  ConsumerState<AuditorReportsScreen> createState() => _AuditorReportsScreenState();
}

class _AuditorReportsScreenState extends ConsumerState<AuditorReportsScreen> {
  String? _selectedAuditId;
  bool _downloading = false;

  /// Downloads the auditor's own audits as an Excel workbook. The backend
  /// scopes `/reports/export.xlsx` to `auditor_id = me`, so no filters are
  /// needed here — every audit assigned to this auditor is included.
  Future<void> _downloadExcel() async {
    setState(() => _downloading = true);
    AppHelpers.showSuccessSnackbar(context, 'Preparing Excel…');
    try {
      final result = await ref
          .read(reportExportClientProvider)
          .downloadXlsx(<String, dynamic>{});
      if (!mounted) return;
      final saved = result.savedPath;
      AppHelpers.showSuccessSnackbar(
        context,
        saved == null ? 'Excel downloaded.' : 'Excel saved to $saved',
      );
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showErrorSnackbar(context, AppHelpers.readableError(e));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(auditorDashboardProvider);

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading reports: $e')),
      data: (data) {
        // Show only audits that have been submitted/completed
        final submittedStatuses = {'submitted', 'completed', 'under_review', 'acknowledged'};
        final completedAudits = data.audits
            .where((a) => submittedStatuses.contains((a.auditSheetStatus ?? '').toLowerCase()) || a.auditSheetSubmittedAt != null)
            .toList();

        if (_selectedAuditId != null && !completedAudits.any((a) => a.id == _selectedAuditId)) {
          _selectedAuditId = null;
        }

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 600),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
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
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('View Audit Reports', style: AppTextStyles.title18),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a completed audit from the list below to view its full report, pass rate, and action plans.',
                      style: AppTextStyles.body14.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    if (completedAudits.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.greyTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No completed reports available at the moment.',
                                style: AppTextStyles.body14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      AppDropdown<String>(
                        label: 'Completed Audit',
                        value: _selectedAuditId,
                        items: completedAudits.map((audit) {
                          final dateStr = AppDateUtils.formatDisplay(audit.date);
                          return DropdownMenuItem(
                            value: audit.id,
                            child: Text('${audit.project} - ${audit.location} ($dateStr)'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedAuditId = val),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          AppButton(
                            label: 'Download Excel',
                            icon: Icons.table_chart_outlined,
                            variant: AppButtonVariant.ghost,
                            isLoading: _downloading,
                            onPressed: _downloading ? null : _downloadExcel,
                          ),
                          AppButton(
                            label: 'View Report',
                            icon: Icons.visibility_outlined,
                            onPressed: _selectedAuditId == null
                                ? null
                                : () {
                                    context.go('/report/$_selectedAuditId');
                                  },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
