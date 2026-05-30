import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../../core/widgets/status_pill.dart';
import '../models/auditor_owner_dashboard_model.dart';
import '../providers/dashboard_provider.dart';

class AuditDetailsScreen extends ConsumerWidget {
  const AuditDetailsScreen({super.key, required this.auditId});

  final String auditId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(auditorDashboardProvider);

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        final audit = data.audits.where((a) => a.id == auditId).firstOrNull;
        if (audit == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off_outlined,
                    color: AppColors.textMuted, size: 48),
                const SizedBox(height: 12),
                Text('Audit not found', style: AppTextStyles.title18),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Back to Dashboard',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => context.go('/auditor/dashboard'),
                ),
              ],
            ),
          );
        }
        return _AuditDetailsBody(audit: audit);
      },
    );
  }
}

class _AuditDetailsBody extends StatelessWidget {
  const _AuditDetailsBody({required this.audit});
  final AuditorAudit audit;

  @override
  Widget build(BuildContext context) {
    final displayStatus = audit.displayStatus;
    final sheetStatus = (audit.auditSheetStatus ?? '').toLowerCase();
    final isSubmitted = ['submitted', 'under_review'].contains(sheetStatus);
    final isAcknowledged = sheetStatus == 'acknowledged';
    final isCompleted = ['completed', 'closed'].contains(audit.status.toLowerCase()) || isAcknowledged;
    final isUpcoming = displayStatus == 'upcoming';
    final isActive = !isSubmitted && !isCompleted && !isUpcoming;
    final hasStarted = sheetStatus == 'draft' || (sheetStatus.isNotEmpty && sheetStatus != 'not_started' && !isSubmitted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero ───────────────────────────────────────────────────────
        PageHero(
          title: audit.project,
          subtitle: 'Audit assignment details — review info and begin your audit',
          icon: Icons.assignment_outlined,
          action: StatusPill(status: _readableStatus(displayStatus)),
        ),
        const SizedBox(height: 20),

        // ── Post-submission waiting notice ─────────────────────────────
        if (isSubmitted && !isAcknowledged)
          _SubmittedNotice(
            onEdit: () => context.go('/auditor/audit/${audit.id}'),
          ),
        if (isSubmitted && !isAcknowledged) const SizedBox(height: 16),

        // ── Detail Cards ───────────────────────────────────────────────
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth > 700;
          final fields = _buildDetailItems(audit);
          if (wide) {
            return AppPanel(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 4,
                ),
                itemCount: fields.length,
                itemBuilder: (context, i) => fields[i],
              ),
            );
          }
          return AppPanel(
            child: Column(
              children: fields
                  .expand((f) => [f, const SizedBox(height: 10)])
                  .toList()
                ..removeLast(),
            ),
          );
        }),
        const SizedBox(height: 20),

        // ── Action Panel ───────────────────────────────────────────────
        AppPanel(
          title: 'Actions',
          icon: Icons.touch_app_outlined,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (isActive)
                AppButton(
                  label: hasStarted ? 'Resume Audit' : 'Start Audit',
                  icon: hasStarted
                      ? Icons.play_circle_outlined
                      : Icons.play_arrow_rounded,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => context.go('/auditor/audit/${audit.id}'),
                ),
              if (isSubmitted && !isAcknowledged)
                AppButton(
                  label: 'Edit Audit',
                  icon: Icons.edit_outlined,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => context.go('/auditor/audit/${audit.id}'),
                ),
              if (isCompleted || isAcknowledged)
                AppButton(
                  label: 'View Report',
                  icon: Icons.description_outlined,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => context.go('/report/${audit.id}'),
                ),
              AppButton(
                label: 'Back to Dashboard',
                icon: Icons.arrow_back_rounded,
                variant: AppButtonVariant.ghost,
                onPressed: () => context.go('/auditor/dashboard'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDetailItems(AuditorAudit audit) {
    return [
      _DetailItem(
        icon: Icons.business_outlined,
        label: 'Project Name',
        value: audit.project,
      ),
      _DetailItem(
        icon: Icons.location_on_outlined,
        label: 'Location',
        value: audit.location,
        color: AppColors.secondary,
      ),
      _DetailItem(
        icon: Icons.calendar_today_outlined,
        label: 'Audit Date',
        value: AppDateUtils.formatDisplay(audit.date),
        color: AppColors.warning,
      ),
      _DetailItem(
        icon: Icons.access_time_outlined,
        label: 'Time',
        value: _formatTime(audit.date),
        color: AppColors.warning,
      ),
      _DetailItem(
        icon: Icons.person_outline,
        label: 'Project Manager',
        value: audit.projectManager ?? '—',
        color: AppColors.primary,
      ),
      _DetailItem(
        icon: Icons.people_outline,
        label: 'Cluster Manager',
        value: audit.clusterManager ?? '—',
        color: AppColors.purple,
      ),
      _DetailItem(
        icon: Icons.flag_outlined,
        label: 'Audit Plan Status',
        value: audit.status.replaceAll('_', ' '),
      ),
      _DetailItem(
        icon: Icons.fact_check_outlined,
        label: 'Sheet Status',
        value: audit.auditSheetStatus?.replaceAll('_', ' ') ?? 'Not started',
        color: _sheetStatusColor(audit.auditSheetStatus ?? ''),
      ),
    ];
  }

  Color _sheetStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
      case 'acknowledged':
        return AppColors.secondary;
      case 'draft':
      case 'in_progress':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  String _readableStatus(String displayStatus) {
    switch (displayStatus) {
      case 'upcoming': return 'Upcoming';
      case 'pending': return 'Pending';
      case 'in_progress': return 'In Progress';
      case 'submitted': return 'Submitted';
      case 'acknowledged': return 'Acknowledged';
      case 'completed': return 'Completed';
      default: return displayStatus;
    }
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.greyTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: tone),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTextStyles.body11),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.medium13,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmittedNotice extends StatelessWidget {
  const _SubmittedNotice({required this.onEdit});
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amberTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded,
              color: AppColors.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waiting for Acknowledgment',
                  style: AppTextStyles.medium14.copyWith(
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Your audit has been submitted. You may still edit it until the project owner acknowledges.',
                  style: AppTextStyles.body12,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onEdit,
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}
