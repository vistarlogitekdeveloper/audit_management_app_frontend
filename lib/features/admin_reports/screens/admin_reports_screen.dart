import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_sheet_header.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../../core/widgets/status_pill.dart';
import '../../audit_plan/models/audit_plan_model.dart';
import '../../audit_plan/providers/audit_plan_provider.dart';
import '../../dashboard/models/dashboard_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/pass_rate_chart.dart';
import '../models/report_analytics_model.dart';
import '../providers/report_analytics_provider.dart';
import '../services/report_export_client.dart';
import '../widgets/analytics_charts.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  DateTimeRange? _dateRange;
  String? _projectId;
  String? _clusterId;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(auditPlanProvider).bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(adminDashboardProvider);
    final auditPlan = ref.watch(auditPlanProvider);

    return dashboardAsync.when(
      loading: () => const LoadingState(message: 'Loading reports…'),
      error: (error, _) => ErrorState(
        message: AppHelpers.readableError(error),
        onRetry: () => ref.invalidate(adminDashboardProvider),
      ),
      data: (dashboard) => _buildContent(dashboard, auditPlan),
    );
  }

  Widget _buildContent(
      AdminDashboardModel dashboard, AuditPlanProvider auditPlan) {
    final filteredPlans = _filterPlans(auditPlan.plans);
    final stats = dashboard.stats;
    final wide = MediaQuery.sizeOf(context).width >= 1100;

    // Real per-cluster / per-project performance, computed server-side over the
    // audit sheets (the dashboard's clusterPassRates is an empty stub).
    final analyticsAsync = ref.watch(reportAnalyticsProvider(_analyticsQuery()));
    final analytics = analyticsAsync.valueOrNull;
    final passRateItems = (analytics?.clusters ?? [])
        .map((c) => {'name': c.name, 'percent': c.passPercent})
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHero(
          title: 'Reports & analytics',
          subtitle:
              'Slice audits by date, project, and cluster. Export filtered results as CSV.',
          icon: Icons.insights_outlined,
          action: _ExportMenu(onPick: _runExport),
        ),
        const SizedBox(height: 18),
        if (auditPlan.bootstrapError != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.danger.withValues(alpha: 0.32)),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off_rounded,
                    color: AppColors.danger, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Some report data failed to load — filters and totals '
                    'may be incomplete.',
                    style: AppTextStyles.body12,
                  ),
                ),
                TextButton(
                  onPressed: () => ref.read(auditPlanProvider).bootstrap(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        _buildFilters(auditPlan),
        const SizedBox(height: 14),
        _buildSummaryCards(stats, filteredPlans),
        const SizedBox(height: 14),
        _buildProjectPerformancePanel(analyticsAsync),
        const SizedBox(height: 14),
        _buildPointAnalysisPanel(analyticsAsync),
        const SizedBox(height: 14),
        if (analytics != null && analytics.projects.isNotEmpty) ...[
          _buildChartsSection(analytics, wide),
          const SizedBox(height: 14),
        ],
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPassRatePanel(passRateItems)),
              const SizedBox(width: 14),
              Expanded(child: _buildDistributionPanel(filteredPlans)),
            ],
          )
        else ...[
          _buildPassRatePanel(passRateItems),
          const SizedBox(height: 14),
          _buildDistributionPanel(filteredPlans),
        ],
        const SizedBox(height: 14),
        _buildAuditTable(filteredPlans),
      ],
    );
  }

  Widget _buildFilters(AuditPlanProvider auditPlan) {
    return AppPanel(
      title: 'Filters',
      icon: Icons.filter_alt_outlined,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _filterChip(
            label: _dateRange == null
                ? 'Date range: All'
                : 'Date: ${AppDateUtils.formatDisplay(_dateRange!.start)} – ${AppDateUtils.formatDisplay(_dateRange!.end)}',
            icon: Icons.calendar_today_outlined,
            onTap: _pickDateRange,
            onClear: _dateRange == null
                ? null
                : () => setState(() => _dateRange = null),
          ),
          _filterChip(
            label: _projectId == null
                ? 'Project: All'
                : 'Project: ${_findProjectName(auditPlan.projects, _projectId!)}',
            icon: Icons.business_outlined,
            onTap: () => _pickProject(auditPlan.projects),
            onClear: _projectId == null
                ? null
                : () => setState(() => _projectId = null),
          ),
          _filterChip(
            label: _clusterId == null
                ? 'Cluster: All'
                : 'Cluster: ${_findUserName(auditPlan.clusterManagers, _clusterId!)}',
            icon: Icons.account_tree_outlined,
            onTap: () => _pickCluster(auditPlan.clusterManagers),
            onClear: _clusterId == null
                ? null
                : () => setState(() => _clusterId = null),
          ),
          _statusChips(),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.greyTint,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.medium13),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(99),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded, size: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChips() {
    const statuses = [
      ('all', 'All'),
      ('draft', 'Draft'),
      ('released', 'Released'),
      ('completed', 'Completed'),
      ('overdue', 'Overdue'),
    ];
    return Wrap(
      spacing: 6,
      children: statuses.map((entry) {
        final selected = _statusFilter == entry.$1;
        return ChoiceChip(
          label: Text(entry.$2),
          selected: selected,
          onSelected: (_) => setState(() => _statusFilter = entry.$1),
          selectedColor: AppColors.primary.withValues(alpha: 0.12),
          labelStyle: AppTextStyles.medium12.copyWith(
            color:
                selected ? AppColors.primary : AppColors.textSecondary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.32)
                  : AppColors.border,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCards(
      DashboardStats stats, List<AuditPlanModel> filtered) {
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
          label: 'Audits in range',
          value: '${filtered.length}',
          icon: Icons.assignment_outlined,
        ),
        InfoMetric(
          label: 'Completed',
          value: '${stats.completed}',
          icon: Icons.verified_outlined,
          color: AppColors.success,
        ),
        InfoMetric(
          label: 'Pending review',
          value: '${stats.pendingReview}',
          icon: Icons.rate_review_outlined,
          color: AppColors.warning,
        ),
        InfoMetric(
          label: 'Overdue plans',
          value: '${stats.overdueActionPlans}',
          icon: Icons.warning_amber_rounded,
          color: AppColors.danger,
        ),
      ],
    );
  }

  Widget _buildPassRatePanel(List<Map<String, dynamic>> items) {
    return AppPanel(
      title: 'Pass rate by cluster',
      icon: Icons.bar_chart_outlined,
      child: items.isEmpty
          ? const EmptyPanel(message: 'No cluster pass rate data yet.')
          : PassRateChart(items: items),
    );
  }

  Widget _buildDistributionPanel(List<AuditPlanModel> filtered) {
    final draft =
        filtered.where((p) => p.status.toLowerCase() == 'draft').length;
    final released =
        filtered.where((p) => p.status.toLowerCase() == 'released').length;
    final completed =
        filtered.where((p) => p.status.toLowerCase() == 'completed').length;
    final other = filtered.length - draft - released - completed;
    final segments = [
      _PieSegment('Draft', draft, AppColors.textMuted),
      _PieSegment('Released', released, AppColors.primary),
      _PieSegment('Completed', completed, AppColors.success),
      if (other > 0) _PieSegment('Other', other, AppColors.warning),
    ].where((s) => s.value > 0).toList();

    return AppPanel(
      title: 'Status distribution',
      icon: Icons.pie_chart_outline,
      child: segments.isEmpty
          ? const EmptyPanel(message: 'No audits match the current filter.')
          : Row(
              children: [
                SizedBox(
                  height: 180,
                  width: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: segments
                          .map(
                            (segment) => PieChartSectionData(
                              value: segment.value.toDouble(),
                              color: segment.color,
                              title: '${segment.value}',
                              radius: 50,
                              titleStyle: AppTextStyles.medium12
                                  .copyWith(color: AppColors.white),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: segments
                        .map((segment) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: segment.color,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(segment.label,
                                        style: AppTextStyles.body13),
                                  ),
                                  Text('${segment.value}',
                                      style: AppTextStyles.medium13),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAuditTable(List<AuditPlanModel> filtered) {
    return AppPanel(
      title: 'Audit list',
      icon: Icons.list_alt_outlined,
      child: filtered.isEmpty
          ? const EmptyPanel(message: 'No audits match the current filter.')
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.surface2),
                headingTextStyle: AppTextStyles.medium13.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                dataTextStyle: AppTextStyles.body13.copyWith(
                  color: AppColors.textPrimary,
                ),
                columns: const [
                  DataColumn(label: Text('Project')),
                  DataColumn(label: Text('Auditor')),
                  DataColumn(label: Text('Cluster Mgr')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Status')),
                ],
                rows: filtered
                    .map((plan) => DataRow(cells: [
                          DataCell(SizedBox(
                              width: 220,
                              child: Text(plan.projectName,
                                  style: AppTextStyles.medium13))),
                          DataCell(Text(plan.auditorName,
                              style: AppTextStyles.body13)),
                          DataCell(Text(plan.clusterManager,
                              style: AppTextStyles.body13)),
                          DataCell(Text(
                              AppDateUtils.formatDisplay(plan.auditDate),
                              style: AppTextStyles.body13)),
                          DataCell(StatusPill(status: plan.status)),
                        ]))
                    .toList(),
              ),
            ),
    );
  }

  List<AuditPlanModel> _filterPlans(List<AuditPlanModel> plans) {
    return plans.where((plan) {
      if (_dateRange != null) {
        final start =
            DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
        final end = DateTime(_dateRange!.end.year, _dateRange!.end.month,
            _dateRange!.end.day, 23, 59, 59);
        if (plan.auditDate.isBefore(start) || plan.auditDate.isAfter(end)) {
          return false;
        }
      }
      if (_statusFilter != 'all' &&
          plan.status.toLowerCase() != _statusFilter) {
        return false;
      }
      // Project & cluster filter are matched against names because the
      // AuditPlanModel only carries denormalized strings (no FK ids).
      return true;
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  Future<void> _pickProject(List<ProjectLookupModel> projects) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _PickerSheet(
        title: 'Select project',
        items: projects.map((p) => (p.id, p.name)).toList(),
      ),
    );
    if (!mounted) return;
    if (selected == 'all') {
      setState(() => _projectId = null);
    } else if (selected != null) {
      setState(() => _projectId = selected);
    }
  }

  Future<void> _pickCluster(List<UserLookupModel> clusters) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _PickerSheet(
        title: 'Select cluster manager',
        items: clusters.map((c) => (c.id, c.name)).toList(),
      ),
    );
    if (!mounted) return;
    if (selected == 'all') {
      setState(() => _clusterId = null);
    } else if (selected != null) {
      setState(() => _clusterId = selected);
    }
  }

  String _findProjectName(List<ProjectLookupModel> projects, String id) {
    for (final p in projects) {
      if (p.id == id) return p.name;
    }
    return id;
  }

  String _findUserName(List<UserLookupModel> users, String id) {
    for (final u in users) {
      if (u.id == id) return u.name;
    }
    return id;
  }

  Map<String, dynamic> _currentFilters() {
    return <String, dynamic>{
      if (_dateRange != null)
        'from_date': _dateRange!.start.toIso8601String().split('T').first,
      if (_dateRange != null)
        'to_date': _dateRange!.end.toIso8601String().split('T').first,
      if (_projectId != null) 'project_id': _projectId,
      if (_clusterId != null) 'cluster_manager_id': _clusterId,
      if (_statusFilter != 'all') 'status': _statusFilter,
    };
  }

  AnalyticsQuery _analyticsQuery() {
    return AnalyticsQuery(
      fromDate: _dateRange?.start.toIso8601String().split('T').first,
      toDate: _dateRange?.end.toIso8601String().split('T').first,
      projectId: _projectId,
      clusterManagerId: _clusterId,
      status: _statusFilter == 'all' ? null : _statusFilter,
    );
  }

  Color _perfColor(double pct) {
    if (pct >= 85) return AppColors.success;
    if (pct >= 60) return AppColors.warning;
    return AppColors.danger;
  }

  /// The four graphs mirrored from the consolidated analysis workbook:
  /// Pass-vs-Fail by project (column), Combined score (pie), Pareto of failure
  /// points (bar + cumulative line), and Pass-vs-Fail by audit point (bar).
  Widget _buildChartsSection(ReportAnalytics a, bool wide) {
    final byProject = AppPanel(
      title: 'Pass vs fail by project',
      icon: Icons.bar_chart_rounded,
      child: PassFailByProjectChart(projects: a.projects),
    );
    final combined = AppPanel(
      title: 'Combined score',
      icon: Icons.pie_chart_outline,
      child: CombinedScorePie(
        pass: a.overall.totalPass,
        fail: a.overall.totalFail,
      ),
    );
    final pareto = AppPanel(
      title: 'Pareto — failure points',
      icon: Icons.show_chart_rounded,
      child: ParetoChart(points: a.points),
    );
    final byPoint = AppPanel(
      title: 'Pass vs fail by audit point',
      icon: Icons.stacked_bar_chart_rounded,
      child: PassFailByPointChart(points: a.points),
    );

    return Column(
      children: [
        if (wide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: byProject),
                const SizedBox(width: 14),
                Expanded(flex: 2, child: combined),
              ],
            ),
          )
        else ...[
          byProject,
          const SizedBox(height: 14),
          combined,
        ],
        const SizedBox(height: 14),
        pareto,
        const SizedBox(height: 14),
        byPoint,
      ],
    );
  }

  Widget _buildProjectPerformancePanel(AsyncValue<ReportAnalytics> async) {
    return AppPanel(
      title: 'Project performance',
      icon: Icons.leaderboard_outlined,
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Couldn\'t load performance analytics.',
                  style: AppTextStyles.body13),
            ),
            TextButton(
              onPressed: () =>
                  ref.invalidate(reportAnalyticsProvider(_analyticsQuery())),
              child: const Text('Retry'),
            ),
          ],
        ),
        data: (a) {
          if (a.projects.isEmpty) {
            return const EmptyPanel(
                message: 'No performance data for the current filter.');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _perfHeader(a),
              const SizedBox(height: 14),
              ...a.projects
                  .asMap()
                  .entries
                  .map((e) => _perfRow(e.key + 1, e.value)),
            ],
          );
        },
      ),
    );
  }

  Widget _perfHeader(ReportAnalytics a) {
    final top = a.topProject;
    final bottom = a.bottomProject;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _perfPill(
          icon: Icons.percent_rounded,
          label: 'Overall pass',
          value: '${a.overall.avgPassPercent.toStringAsFixed(1)}%',
          color: _perfColor(a.overall.avgPassPercent),
        ),
        if (top != null)
          _perfPill(
            icon: Icons.emoji_events_outlined,
            label: 'Top: ${top.name}',
            value: '${top.passPercent.toStringAsFixed(1)}%',
            color: AppColors.success,
          ),
        if (bottom != null && bottom.id != top?.id)
          _perfPill(
            icon: Icons.trending_down_rounded,
            label: 'Needs work: ${bottom.name}',
            value: '${bottom.passPercent.toStringAsFixed(1)}%',
            color: AppColors.danger,
          ),
        _perfPill(
          icon: Icons.fact_check_outlined,
          label: 'Points audited',
          value: '${a.overall.totalAudited}',
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _perfPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Text(label, style: AppTextStyles.body12),
          const SizedBox(width: 6),
          Text(value, style: AppTextStyles.medium13.copyWith(color: color)),
        ],
      ),
    );
  }

  Color _failColor(double failPct) {
    if (failPct >= 50) return AppColors.danger;
    if (failPct >= 25) return AppColors.warning;
    return AppColors.success;
  }

  Widget _buildPointAnalysisPanel(AsyncValue<ReportAnalytics> async) {
    return AppPanel(
      title: 'Audit point analysis',
      icon: Icons.analytics_outlined,
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Couldn\'t load point analysis.',
                  style: AppTextStyles.body13),
            ),
            TextButton(
              onPressed: () =>
                  ref.invalidate(reportAnalyticsProvider(_analyticsQuery())),
              child: const Text('Retry'),
            ),
          ],
        ),
        data: (a) {
          final scored = a.points.where((p) => p.scored > 0).toList();
          if (scored.isEmpty) {
            return const EmptyPanel(
                message: 'No scored audit points for the current filter.');
          }
          final failing = scored.where((p) => p.fail > 0).toList();
          final clean = scored.length - failing.length;
          final worst = a.worstPoint;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Which audit points fail most across the selected audits '
                '(ranked worst first).',
                style: AppTextStyles.body12,
              ),
              const SizedBox(height: 10),
              if (worst != null && worst.fail > 0) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.28)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.priority_high_rounded,
                          size: 18, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Biggest gap: ${worst.name} — fails in '
                          '${worst.failPercent.toStringAsFixed(0)}% of audits '
                          '(${worst.fail} of ${worst.scored}).',
                          style: AppTextStyles.medium13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (failing.isEmpty)
                Text('Every audited point passed. 🎉',
                    style: AppTextStyles.body13)
              else
                ...failing.map(_pointRow),
              if (clean > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '$clean point${clean == 1 ? '' : 's'} passed at every audit.',
                  style: AppTextStyles.body12
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _pointRow(PointStat p) {
    final color = _failColor(p.failPercent);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Text('${p.rank}', style: AppTextStyles.medium12),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(p.name,
                          style: AppTextStyles.medium13,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text('${p.failPercent.toStringAsFixed(0)}% fail',
                        style: AppTextStyles.medium13.copyWith(color: color)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (p.failPercent / 100).clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: AppColors.surface2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${p.fail} fail · ${p.pass} pass'
                  '${p.na > 0 ? ' · ${p.na} N/A' : ''} · '
                  'cumulative ${p.cumulativePercent.toStringAsFixed(0)}%',
                  style: AppTextStyles.body12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _perfRow(int rank, GroupPerformance p) {
    final pct = p.passPercent;
    final color = _perfColor(pct);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Text('$rank', style: AppTextStyles.medium12),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(p.name,
                          style: AppTextStyles.medium13,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text('${pct.toStringAsFixed(1)}%',
                        style: AppTextStyles.medium13.copyWith(color: color)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: AppColors.surface2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${p.audits} audit${p.audits == 1 ? '' : 's'} · '
                  '${p.totalFail} fail point${p.totalFail == 1 ? '' : 's'}'
                  '${p.location.isNotEmpty ? ' · ${p.location}' : ''}',
                  style: AppTextStyles.body12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runExport(_ExportFormat fmt) async {
    final client = ref.read(reportExportClientProvider);
    final filters = _currentFilters();
    AppHelpers.showSuccessSnackbar(context, 'Preparing ${fmt.label}…');
    try {
      final result = switch (fmt) {
        _ExportFormat.csv => await client.downloadCsv(filters),
        _ExportFormat.xlsx => await client.downloadXlsx(filters),
        _ExportFormat.pdf => await client.downloadPdf(filters),
      };
      if (!mounted) return;
      final saved = result.savedPath;
      AppHelpers.showSuccessSnackbar(
        context,
        saved == null
            ? '${fmt.label} downloaded.'
            : '${fmt.label} saved to $saved',
      );
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showErrorSnackbar(context, AppHelpers.readableError(e));
    }
  }
}

enum _ExportFormat { pdf, xlsx, csv }

extension on _ExportFormat {
  String get label => switch (this) {
        _ExportFormat.pdf => 'PDF',
        _ExportFormat.xlsx => 'Excel',
        _ExportFormat.csv => 'CSV',
      };
  IconData get icon => switch (this) {
        _ExportFormat.pdf => Icons.picture_as_pdf_outlined,
        _ExportFormat.xlsx => Icons.table_chart_outlined,
        _ExportFormat.csv => Icons.text_snippet_outlined,
      };
}

class _ExportMenu extends StatelessWidget {
  const _ExportMenu({required this.onPick});

  final Future<void> Function(_ExportFormat) onPick;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ExportFormat>(
      tooltip: 'Export filtered report',
      onSelected: (fmt) => onPick(fmt),
      itemBuilder: (_) => _ExportFormat.values
          .map(
            (fmt) => PopupMenuItem(
              value: fmt,
              child: Row(
                children: [
                  Icon(fmt.icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text('Export as ${fmt.label}'),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_rounded, size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Export',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _PieSegment {
  const _PieSegment(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({required this.title, required this.items});

  final String title;
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSheetHeader(title: title),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.clear_all_rounded),
                  title: const Text('All'),
                  onTap: () => Navigator.of(context).pop('all'),
                ),
                const Divider(height: 1),
                ...items.map(
                  (entry) => ListTile(
                    title: Text(entry.$2),
                    onTap: () => Navigator.of(context).pop(entry.$1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
