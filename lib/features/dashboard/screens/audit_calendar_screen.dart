import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../dashboard/models/dashboard_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../audit_plan/providers/audit_plan_provider.dart';

class AuditCalendarScreen extends ConsumerStatefulWidget {
  const AuditCalendarScreen({super.key});

  @override
  ConsumerState<AuditCalendarScreen> createState() =>
      _AuditCalendarScreenState();
}

class _AuditCalendarScreenState extends ConsumerState<AuditCalendarScreen> {
  @override
  void initState() {
    super.initState();
    // The table reads the full audit-plan list directly (GET /audit-plans),
    // because the dashboard's upcomingAudits filters by status and hides
    // acknowledged / closed plans — leaving the table blank even when plans
    // exist. fetchPlans() returns every plan with project / incharge /
    // cluster manager nested, which is everything the table needs.
    Future.microtask(() {
      final planProvider = ref.read(auditPlanProvider);
      if (planProvider.plans.isEmpty) planProvider.fetchPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(adminDashboardProvider);
    final auditPlanState = ref.watch(auditPlanProvider);

    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.danger, size: 32),
            const SizedBox(height: 12),
            Text('Failed to load data', style: AppTextStyles.title16),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(adminDashboardProvider);
                ref.read(auditPlanProvider).fetchPlans();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (dashboard) => _AuditCalendarContent(
        dashboard: dashboard,
        auditPlanState: auditPlanState,
      ),
    );
  }
}

class _AuditCalendarContent extends StatefulWidget {
  const _AuditCalendarContent({
    required this.dashboard,
    required this.auditPlanState,
  });

  final AdminDashboardModel dashboard;
  final AuditPlanProvider auditPlanState;

  @override
  State<_AuditCalendarContent> createState() => _AuditCalendarContentState();
}

class _AuditCalendarContentState extends State<_AuditCalendarContent> {
  // Filters
  String? _filterProject;
  String? _filterIncharge;
  String? _filterClusterManager;
  String? _filterAuditor;
  String? _filterAddress;
  String? _filterArea;
  String? _filterStatus;
  bool _sortPlanAsc = true;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    final stats = widget.dashboard.stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: width >= 1100 ? 4 : 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: compact ? 1.25 : 1.65,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _MetricCard(
              label: 'Planned audits',
              value: '${stats.totalPlanned}',
              icon: Icons.event_note_outlined,
              color: AppColors.primary,
              helper: 'Current cycle',
            ),
            _MetricCard(
              label: 'Completed',
              value: '${stats.completed}',
              icon: Icons.verified_outlined,
              color: AppColors.secondary,
              helper: 'Closed audits',
            ),
            _MetricCard(
              label: 'Pending review',
              value: '${stats.pendingReview}',
              icon: Icons.rate_review_outlined,
              color: AppColors.warning,
              helper: 'Needs attention',
            ),
            _MetricCard(
              label: 'Overdue plans',
              value: '${stats.overdueActionPlans}',
              icon: Icons.warning_amber_rounded,
              color: AppColors.danger,
              helper: 'Past due date',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Audit Calendar Data', style: AppTextStyles.title16),
              ),
              const Divider(height: 1),
              _buildTable(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    List<Map<String, dynamic>> rows = [];

    // Show a loading placeholder while the audit-plans list is being fetched
    // for the first time.
    if (widget.auditPlanState.isLoading &&
        widget.auditPlanState.plans.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Build rows straight from the audit-plans response. Each plan already
    // carries the nested project, projectIncharge and clusterManager objects,
    // so no separate /projects lookup is needed.
    for (final plan in widget.auditPlanState.plans) {
      rows.add({
        'auditId': plan.id,
        'projectName': plan.projectName.isNotEmpty ? plan.projectName : '—',
        'incharge': plan.projectIncharge.isNotEmpty
            ? plan.projectIncharge
            : '—',
        'clusterManager': plan.clusterManager.isNotEmpty
            ? plan.clusterManager
            : '—',
        'auditor': plan.auditorName.isNotEmpty ? plan.auditorName : '—',
        'address': plan.location.isNotEmpty ? plan.location : '—',
        'area': plan.location.isNotEmpty ? plan.location : '—',
        'planDate': plan.auditDate,
        'status': plan.status,
      });
    }

    // Apply filters
    if (_filterProject != null) {
      rows = rows.where((r) => r['projectName'] == _filterProject).toList();
    }
    if (_filterIncharge != null) {
      rows = rows.where((r) => r['incharge'] == _filterIncharge).toList();
    }
    if (_filterClusterManager != null) {
      rows = rows.where((r) => r['clusterManager'] == _filterClusterManager).toList();
    }
    if (_filterAuditor != null) {
      rows = rows.where((r) => r['auditor'] == _filterAuditor).toList();
    }
    if (_filterAddress != null) {
      rows = rows.where((r) => r['address'] == _filterAddress).toList();
    }
    if (_filterArea != null) {
      rows = rows.where((r) => r['area'] == _filterArea).toList();
    }
    if (_filterStatus != null) {
      rows = rows.where((r) => r['status'] == _filterStatus).toList();
    }

    // Sort
    rows.sort((a, b) {
      DateTime dateA = a['planDate'];
      DateTime dateB = b['planDate'];
      return _sortPlanAsc ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });

    // Unique values for dropdowns
    final uniqueProjects = rows.map((r) => r['projectName'] as String).toSet().toList();
    final uniqueIncharge = rows.map((r) => r['incharge'] as String).toSet().toList();
    final uniqueClusters = rows.map((r) => r['clusterManager'] as String).toSet().toList();
    final uniqueAuditors = rows.map((r) => r['auditor'] as String).toSet().toList();
    final uniqueAddresses = rows.map((r) => r['address'] as String).toSet().toList();
    final uniqueAreas = rows.map((r) => r['area'] as String).toSet().toList();
    final uniqueStatuses = rows.map((r) => r['status'] as String).toSet().toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.surface2),
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.4,
        ),
        // Material's default DataTable text style is anchored to
        // light-theme colours; without an explicit dataTextStyle the row
        // text turns near-black on a dark surface and reads as invisible.
        dataTextStyle: AppTextStyles.body13.copyWith(
          color: AppColors.textPrimary,
        ),
        dataRowMaxHeight: 60,
        dataRowMinHeight: 48,
        columnSpacing: 20,
        columns: [
          const DataColumn(label: Text('SR.no')),
          DataColumn(
            label: _buildHeaderFilter(
              'Name of Project',
              _filterProject,
              uniqueProjects,
              (val) => setState(() => _filterProject = val),
            ),
          ),
          DataColumn(
            label: _buildHeaderFilter(
              'Project Incharge/Manager',
              _filterIncharge,
              uniqueIncharge,
              (val) => setState(() => _filterIncharge = val),
            ),
          ),
          DataColumn(
            label: _buildHeaderFilter(
              'Cluster Manager',
              _filterClusterManager,
              uniqueClusters,
              (val) => setState(() => _filterClusterManager = val),
            ),
          ),
          DataColumn(
            label: _buildHeaderFilter(
              'Auditor',
              _filterAuditor,
              uniqueAuditors,
              (val) => setState(() => _filterAuditor = val),
            ),
          ),
          DataColumn(
            label: _buildHeaderFilter(
              'Address',
              _filterAddress,
              uniqueAddresses,
              (val) => setState(() => _filterAddress = val),
            ),
          ),
          DataColumn(
            label: _buildHeaderFilter(
              'Area',
              _filterArea,
              uniqueAreas,
              (val) => setState(() => _filterArea = val),
              icon: Icons.filter_alt_outlined,
            ),
          ),
          DataColumn(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Plan'),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    setState(() {
                      _sortPlanAsc = !_sortPlanAsc;
                    });
                  },
                  child: Icon(
                    _sortPlanAsc ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          DataColumn(
            label: _buildHeaderFilter(
              'Status',
              _filterStatus,
              uniqueStatuses,
              (val) => setState(() => _filterStatus = val),
            ),
          ),
        ],
        rows: List.generate(rows.length, (index) {
          final row = rows[index];
          return DataRow(
            color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
              if (index.isEven) {
                return Colors.grey.withValues(alpha: 0.05);
              }
              return null;
            }),
            cells: [
              DataCell(Text('${index + 1}')),
              DataCell(Text(row['projectName'])),
              DataCell(Text(row['incharge'])),
              DataCell(Text(row['clusterManager'])),
              DataCell(Text(row['auditor'])),
              DataCell(Text(row['address'])),
              DataCell(Text(row['area'])),
              DataCell(Text(DateFormat('dd-MMM').format(row['planDate']))),
              DataCell(Text(row['status'])),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeaderFilter(
    String label,
    String? currentValue,
    List<String> items,
    Function(String?) onChanged, {
    IconData icon = Icons.arrow_drop_down,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: 4),
        PopupMenuButton<String?>(
          icon: Icon(icon, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(maxHeight: 300),
          onSelected: onChanged,
          itemBuilder: (context) {
            return [
              const PopupMenuItem<String?>(
                value: null,
                child: Text('All'),
              ),
              ...items.map(
                (item) => PopupMenuItem<String?>(
                  value: item,
                  child: Text(item, style: TextStyle(
                    fontWeight: currentValue == item ? FontWeight.bold : FontWeight.normal,
                  )),
                ),
              ),
            ];
          },
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.helper,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(helper, style: AppTextStyles.body11),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.statValue),
              const SizedBox(height: 4),
              Text(label, style: AppTextStyles.body13),
            ],
          ),
        ],
      ),
    );
  }
}
