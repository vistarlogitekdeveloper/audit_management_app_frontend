import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../dashboard/models/auditor_owner_dashboard_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class PerformAuditScreen extends ConsumerStatefulWidget {
  const PerformAuditScreen({super.key});

  @override
  ConsumerState<PerformAuditScreen> createState() => _PerformAuditScreenState();
}

class _PerformAuditScreenState extends ConsumerState<PerformAuditScreen> {
  String? _selectedAuditId;

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(auditorDashboardProvider);

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading scheduled audits: $e')),
      data: (data) {
        // Show audits that are released but NOT yet submitted
        final submittedStatuses = {'submitted', 'completed', 'under_review', 'acknowledged'};
        final activeAudits = <AuditorAudit>[];
        final seenIds = <String>{};

        for (final audit in data.audits) {
          // Skip if already seen this ID (prevent duplicates)
          if (seenIds.contains(audit.id)) continue;

          final planStatus = audit.status.toLowerCase();
          final sheetStatus = (audit.auditSheetStatus ?? '').toLowerCase();
          
          // An audit is active only if it's in a released/started state 
          // AND the sheet itself hasn't been submitted/completed yet.
          final isPlanActive = ['assigned', 'in progress', 'scheduled', 'released'].contains(planStatus);
          final isSheetPending = !['submitted', 'completed', 'under_review', 'acknowledged'].contains(sheetStatus) && 
                                audit.auditSheetSubmittedAt == null;

          // If the plan is already marked submitted, completed or acknowledged at the plan level, skip it
          if (['submitted', 'completed', 'acknowledged', 'closed'].contains(planStatus)) continue;

          if (isPlanActive && isSheetPending) {
            activeAudits.add(audit);
            seenIds.add(audit.id);
          }
        }

        // Ensure the selected ID is still valid, else reset
        if (_selectedAuditId != null && !activeAudits.any((a) => a.id == _selectedAuditId)) {
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
                    Text('Select Scheduled Audit', style: AppTextStyles.title18),
                    const SizedBox(height: 8),
                    Text(
                      'Choose an assigned audit from the list below to perform the audit sheet execution.',
                      style: AppTextStyles.body14.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    if (activeAudits.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.greyTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No scheduled audits available for you at the moment.',
                                style: AppTextStyles.body14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      AppDropdown<String>(
                        label: 'Scheduled Audit',
                        value: _selectedAuditId,
                        items: activeAudits.map((audit) {
                          final dateStr = AppDateUtils.formatDisplay(audit.date);
                          return DropdownMenuItem(
                            value: audit.id,
                            child: Text('${audit.project} - ${audit.location} ($dateStr)'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedAuditId = val),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AppButton(
                            label: 'Start Audit',
                            icon: Icons.play_arrow_rounded,
                            onPressed: _selectedAuditId == null
                                ? null
                                : () {
                                    context.go('/auditor/audit/$_selectedAuditId');
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
