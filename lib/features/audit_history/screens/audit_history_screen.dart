import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../../core/widgets/status_pill.dart';
import '../../dashboard/models/auditor_owner_dashboard_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class AuditHistoryScreen extends ConsumerStatefulWidget {
  const AuditHistoryScreen({super.key});

  @override
  ConsumerState<AuditHistoryScreen> createState() => _AuditHistoryScreenState();
}

class _AuditHistoryScreenState extends ConsumerState<AuditHistoryScreen> {
  DateTimeRange? _dateRange;
  String _statusFilter = 'all';
  String _projectFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(auditorDashboardProvider);

    return asyncData.when(
      loading: () => const LoadingState(message: 'Loading audit history…'),
      error: (e, _) => ErrorState(
        message: AppHelpers.readableError(e),
        onRetry: () => ref.invalidate(auditorDashboardProvider),
      ),
      data: (data) {
        final history = data.audits.where(_isHistorical).toList();
        final filtered = _applyFilters(history);
        final stats = _summary(filtered);
        final grouped = _groupByMonth(filtered);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHero(
              title: 'My audit history',
              subtitle:
                  'Submitted and acknowledged audits, grouped by month with pass-rate trends.',
              icon: Icons.history_rounded,
              action: FilledButton.icon(
                onPressed: () => _openFilterSheet(context, history),
                icon: const Icon(Icons.filter_list_rounded, size: 18),
                label: const Text('Filter'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SummaryCards(stats: stats),
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              const AppPanel(
                child:
                    EmptyPanel(message: 'No audits in history match the filter.'),
              )
            else
              ...grouped.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: AppPanel(
                    title: entry.key,
                    icon: Icons.calendar_month_outlined,
                    child: Column(
                      children: entry.value
                          .map((audit) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _HistoryCard(audit: audit),
                              ))
                          .toList(),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  bool _isHistorical(AuditorAudit audit) {
    final sheet = (audit.auditSheetStatus ?? '').toLowerCase();
    return sheet == 'submitted' ||
        sheet == 'under_review' ||
        sheet == 'acknowledged' ||
        sheet == 'completed';
  }

  List<AuditorAudit> _applyFilters(List<AuditorAudit> audits) {
    return audits.where((audit) {
      if (_dateRange != null) {
        final start = DateTime(_dateRange!.start.year, _dateRange!.start.month,
            _dateRange!.start.day);
        final end = DateTime(_dateRange!.end.year, _dateRange!.end.month,
            _dateRange!.end.day, 23, 59, 59);
        if (audit.date.isBefore(start) || audit.date.isAfter(end)) return false;
      }
      if (_statusFilter != 'all') {
        final sheet = (audit.auditSheetStatus ?? '').toLowerCase();
        if (_statusFilter == 'submitted' &&
            !(sheet == 'submitted' || sheet == 'under_review')) {
          return false;
        }
        if (_statusFilter == 'acknowledged' &&
            !(sheet == 'acknowledged' || sheet == 'completed')) {
          return false;
        }
      }
      if (_projectFilter != 'all' && audit.project != _projectFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  _Summary _summary(List<AuditorAudit> audits) {
    final passes = audits
        .where((a) => a.passPercent != null)
        .map((a) => a.passPercent!)
        .toList();
    if (passes.isEmpty) {
      return _Summary(total: audits.length, avg: 0, best: null, worst: null);
    }
    final avg = passes.reduce((a, b) => a + b) / passes.length;
    final best = passes.reduce((a, b) => a > b ? a : b);
    final worst = passes.reduce((a, b) => a < b ? a : b);
    return _Summary(total: audits.length, avg: avg, best: best, worst: worst);
  }

  Map<String, List<AuditorAudit>> _groupByMonth(List<AuditorAudit> audits) {
    final formatter = DateFormat('MMMM yyyy');
    final sorted = [...audits]..sort((a, b) => b.date.compareTo(a.date));
    final grouped = <String, List<AuditorAudit>>{};
    for (final audit in sorted) {
      final key = formatter.format(audit.date);
      grouped.putIfAbsent(key, () => []).add(audit);
    }
    return grouped;
  }

  Future<void> _openFilterSheet(
      BuildContext context, List<AuditorAudit> source) async {
    final projects = source.map((a) => a.project).where((p) => p.isNotEmpty).toSet().toList()
      ..sort();
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _FilterSheet(
        initialDateRange: _dateRange,
        initialStatus: _statusFilter,
        initialProject: _projectFilter,
        projects: projects,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _dateRange = result.dateRange;
      _statusFilter = result.status;
      _projectFilter = result.project;
    });
  }
}

class _Summary {
  const _Summary({
    required this.total,
    required this.avg,
    required this.best,
    required this.worst,
  });

  final int total;
  final double avg;
  final double? best;
  final double? worst;
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.stats});

  final _Summary stats;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return GridView.count(
      crossAxisCount: wide ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: wide ? 2.4 : 1.8,
      children: [
        InfoMetric(
          label: 'Total audits',
          value: '${stats.total}',
          icon: Icons.assignment_outlined,
        ),
        InfoMetric(
          label: 'Average pass %',
          value: '${stats.avg.toStringAsFixed(0)}%',
          icon: Icons.trending_up_rounded,
          color: AppHelpers.passPercentColor(stats.avg),
        ),
        InfoMetric(
          label: 'Best pass %',
          value: stats.best == null ? '—' : '${stats.best!.toStringAsFixed(0)}%',
          icon: Icons.emoji_events_outlined,
          color: AppColors.success,
        ),
        InfoMetric(
          label: 'Worst pass %',
          value: stats.worst == null
              ? '—'
              : '${stats.worst!.toStringAsFixed(0)}%',
          icon: Icons.warning_amber_rounded,
          color: AppColors.danger,
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.audit});

  final AuditorAudit audit;

  @override
  Widget build(BuildContext context) {
    final passColor = audit.passPercent == null
        ? AppColors.textMuted
        : AppHelpers.passPercentColor(audit.passPercent!);
    final ack = (audit.auditSheetStatus ?? '').toLowerCase();
    final statusLabel = ack == 'acknowledged' || ack == 'completed'
        ? 'Acknowledged'
        : 'Submitted';

    return InkWell(
      onTap: () => context.go('/auditor/report/${audit.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.greyTint,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(audit.project, style: AppTextStyles.medium14),
                  const SizedBox(height: 2),
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
                      const SizedBox(width: 12),
                      const Icon(Icons.event_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        AppDateUtils.formatDisplay(audit.date),
                        style: AppTextStyles.body12,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  audit.passPercent == null
                      ? '—'
                      : '${audit.passPercent!.toStringAsFixed(0)}%',
                  style: AppTextStyles.medium14.copyWith(
                    color: passColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                StatusPill(status: statusLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterResult {
  const _FilterResult({this.dateRange, required this.status, required this.project});
  final DateTimeRange? dateRange;
  final String status;
  final String project;
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initialDateRange,
    required this.initialStatus,
    required this.initialProject,
    required this.projects,
  });

  final DateTimeRange? initialDateRange;
  final String initialStatus;
  final String initialProject;
  final List<String> projects;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late DateTimeRange? _dateRange;
  late String _status;
  late String _project;

  @override
  void initState() {
    super.initState();
    _dateRange = widget.initialDateRange;
    _status = widget.initialStatus;
    _project = widget.initialProject;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter history', style: AppTextStyles.title18),
          const SizedBox(height: 14),
          Text('Date range', style: AppTextStyles.medium13),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 3),
                lastDate: now,
                initialDateRange: _dateRange,
              );
              if (picked != null) setState(() => _dateRange = picked);
            },
            icon: const Icon(Icons.calendar_today_outlined, size: 16),
            label: Text(
              _dateRange == null
                  ? 'Any date'
                  : '${AppDateUtils.formatDisplay(_dateRange!.start)} – ${AppDateUtils.formatDisplay(_dateRange!.end)}',
            ),
          ),
          if (_dateRange != null)
            TextButton(
              onPressed: () => setState(() => _dateRange = null),
              child: const Text('Clear date range'),
            ),
          const SizedBox(height: 14),
          Text('Status', style: AppTextStyles.medium13),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: const [
              ('all', 'All'),
              ('submitted', 'Submitted'),
              ('acknowledged', 'Acknowledged'),
            ].map((entry) {
              final selected = _status == entry.$1;
              return ChoiceChip(
                label: Text(entry.$2),
                selected: selected,
                onSelected: (_) => setState(() => _status = entry.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text('Project', style: AppTextStyles.medium13),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _project,
            items: [
              const DropdownMenuItem(value: 'all', child: Text('All projects')),
              ...widget.projects.map(
                (p) => DropdownMenuItem(value: p, child: Text(p)),
              ),
            ],
            onChanged: (value) =>
                setState(() => _project = value ?? 'all'),
            decoration: const InputDecoration(),
          ),
          const SizedBox(height: 18),
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
                  label: 'Apply filters',
                  onPressed: () => Navigator.of(context).pop(_FilterResult(
                    dateRange: _dateRange,
                    status: _status,
                    project: _project,
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
