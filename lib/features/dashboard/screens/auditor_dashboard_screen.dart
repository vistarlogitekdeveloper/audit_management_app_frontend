import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/auditor_owner_dashboard_model.dart';
import '../providers/dashboard_provider.dart';

class AuditorDashboardScreen extends ConsumerWidget {
  const AuditorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(auditorDashboardProvider);
    final user = ref.watch(authProvider).currentUser;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;

    return asyncData.when(
      loading: () => const LoadingState(message: 'Loading your audits…'),
      error: (e, st) => _ErrorPanel(error: e),
      data: (data) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome Hero ──────────────────────────────────────────
            _WelcomeHero(
              userName: user?.name ?? 'Auditor',
              assignedCount: data.assignedCount,
              onStart: () => context.go('/auditor/perform-audit'),
            ),
            const SizedBox(height: 18),

            // ── Stat Cards ────────────────────────────────────────────
            GridView.count(
              crossAxisCount: width >= 900 ? 4 : 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: compact ? 1.4 : 1.8,
              children: [
                _StatCard(
                  value: '${data.assignedCount}',
                  label: 'Total Assigned',
                  icon: Icons.assignment_outlined,
                  color: AppColors.primary,
                  badge: 'Open scope',
                ),
                _StatCard(
                  value: '${data.pendingCount}',
                  label: 'Pending',
                  icon: Icons.pending_actions_outlined,
                  color: AppColors.warning,
                  badge: 'Due soon',
                ),
                _StatCard(
                  value: '${data.completedCount}',
                  label: 'Completed',
                  icon: Icons.verified_outlined,
                  color: AppColors.secondary,
                  badge: 'Submitted',
                ),
                _StatCard(
                  value: '${data.avgPassRate.toStringAsFixed(0)}%',
                  label: 'Avg Pass Rate',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.purple,
                  badge: 'All audits',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Audit List ────────────────────────────────────────────
            if (data.audits.isEmpty)
              const EmptyPanel(
                message: 'No audits assigned yet.\nCheck back soon.',
                icon: Icons.assignment_outlined,
              )
            else
              AppPanel(
                title: 'Assigned Audits',
                icon: Icons.fact_check_outlined,
                child: compact
                    ? _AuditCardList(audits: data.audits)
                    : _AuditTable(audits: data.audits),
              ),
          ],
        );
      },
    );
  }
}

// ── Welcome Hero ─────────────────────────────────────────────────────────────
class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({
    required this.userName,
    required this.assignedCount,
    required this.onStart,
  });

  final String userName;
  final int assignedCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Auditor Dashboard',
                        style: AppTextStyles.medium12.copyWith(
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Hello, ${userName.split(' ').first} 👋',
                  style: AppTextStyles.headline22.copyWith(
                    color: AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  assignedCount > 0
                      ? 'You have $assignedCount audit${assignedCount > 1 ? 's' : ''} assigned. Jump in and get them done!'
                      : 'No new audits assigned. Great job staying on top of things!',
                  style: AppTextStyles.body14.copyWith(
                    color: AppColors.white.withValues(alpha: 0.82),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text('Perform Audit'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.badge,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(badge, style: AppTextStyles.body10),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.statValue.copyWith(
                  color: color,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: AppTextStyles.body12),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Audit Table (desktop) ────────────────────────────────────────────────────
class _AuditTable extends StatelessWidget {
  const _AuditTable({required this.audits});
  final List<AuditorAudit> audits;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.greyTint),
        dataRowMinHeight: 62,
        dataRowMaxHeight: 70,
        columns: const [
          DataColumn(label: Text('Project Name')),
          DataColumn(label: Text('Location')),
          DataColumn(label: Text('Audit Date')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Action')),
        ],
        rows: audits.map((audit) {
          final display = audit.displayStatus;
          return DataRow(
            cells: [
              DataCell(
                InkWell(
                  onTap: () => context.go('/auditor/audit-details/${audit.id}'),
                  child: Text(
                    audit.project,
                    style: AppTextStyles.medium14.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
              DataCell(Text(audit.location)),
              DataCell(Text(AppDateUtils.formatDisplay(audit.date))),
              DataCell(StatusPill(status: _pillLabel(display))),
              DataCell(_ActionButton(audit: audit, displayStatus: display)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Audit Card List (mobile) ─────────────────────────────────────────────────
class _AuditCardList extends StatelessWidget {
  const _AuditCardList({required this.audits});
  final List<AuditorAudit> audits;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: audits.map((audit) {
        final display = audit.displayStatus;
        return _AuditMobileCard(audit: audit, displayStatus: display);
      }).toList(),
    );
  }
}

class _AuditMobileCard extends StatelessWidget {
  const _AuditMobileCard({required this.audit, required this.displayStatus});

  final AuditorAudit audit;
  final String displayStatus;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/auditor/audit-details/${audit.id}'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.greyTint,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(audit.project, style: AppTextStyles.medium14),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              audit.location,
                              style: AppTextStyles.body12,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusPill(status: _pillLabel(displayStatus)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(AppDateUtils.formatDisplay(audit.date), style: AppTextStyles.body12),
              ],
            ),
            const SizedBox(height: 12),
            _ActionButton(audit: audit, displayStatus: displayStatus, fullWidth: true),
          ],
        ),
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.audit,
    required this.displayStatus,
    this.fullWidth = false,
  });

  final AuditorAudit audit;
  final String displayStatus;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    if (['acknowledged', 'completed'].contains(displayStatus)) {
      return AppButton(
        label: 'View Report',
        icon: Icons.visibility_outlined,
        variant: AppButtonVariant.ghost,
        isFullWidth: fullWidth,
        onPressed: () => context.go('/auditor/report/${audit.id}'),
      );
    }
    if (displayStatus == 'submitted') {
      return AppButton(
        label: 'Edit Audit',
        icon: Icons.edit_outlined,
        variant: AppButtonVariant.ghost,
        isFullWidth: fullWidth,
        onPressed: () => context.go('/auditor/audit/${audit.id}'),
      );
    }
    if (displayStatus == 'upcoming') {
      return AppButton(
        label: 'View Details',
        icon: Icons.info_outline,
        variant: AppButtonVariant.ghost,
        isFullWidth: fullWidth,
        onPressed: () => context.go('/auditor/audit-details/${audit.id}'),
      );
    }
    // pending / in_progress / released / assigned
    final sheetStatus = (audit.auditSheetStatus ?? '').toLowerCase();
    final hasStarted = sheetStatus == 'draft' || sheetStatus.isNotEmpty && sheetStatus != 'not_started';
    return AppButton(
      label: hasStarted ? 'Continue Audit' : 'Start Audit',
      icon: hasStarted ? Icons.play_circle_outlined : Icons.play_arrow_rounded,
      isFullWidth: fullWidth,
      onPressed: () => context.go('/auditor/audit/${audit.id}'),
    );
  }
}

String _pillLabel(String displayStatus) {
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

// ── Error Panel ───────────────────────────────────────────────────────────────
class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.redTint,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: 12),
            Text('Failed to load dashboard', style: AppTextStyles.medium14),
            const SizedBox(height: 6),
            Text('$error', style: AppTextStyles.body12, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
