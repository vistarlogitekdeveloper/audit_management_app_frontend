import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../../core/widgets/status_pill.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

final reportServiceProvider = Provider<ReportService>(
  (ref) => ReportService(ref.watch(apiServiceProvider)),
);

class AuditReportScreen extends ConsumerStatefulWidget {
  const AuditReportScreen({super.key, required this.auditId});

  final String auditId;

  @override
  ConsumerState<AuditReportScreen> createState() => _AuditReportScreenState();
}

class _AuditReportScreenState extends ConsumerState<AuditReportScreen> {
  ReportModel? _report;
  String? _pdfPath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _report = await ref.read(reportServiceProvider).getReport(widget.auditId);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final report = _report;
    if (report == null) {
      return Center(
        child: AppButton(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: _load,
        ),
      );
    }

    final wide = MediaQuery.sizeOf(context).width > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHero(
          title: report.projectName,
          subtitle:
              '${report.location} · ${report.auditorName} · ${AppDateUtils.formatDisplay(report.date)}',
          icon: Icons.description_outlined,
          action: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${report.passPercent.toStringAsFixed(0)}% pass',
              style: AppTextStyles.medium14.copyWith(color: AppColors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppPanel(
          child: GridView.count(
            crossAxisCount: wide ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: wide ? 3 : 2.1,
            children: [
              InfoMetric(
                label: 'Audited points',
                value: '${report.totalAudited}',
                icon: Icons.checklist_rounded,
              ),
              InfoMetric(
                label: 'Pass count',
                value: '${report.passCount}',
                icon: Icons.check_circle_outline,
                color: AppColors.success,
              ),
              InfoMetric(
                label: 'Fail count',
                value: '${report.failCount}',
                icon: Icons.error_outline,
                color: AppColors.danger,
              ),
              InfoMetric(
                label: 'Cluster manager',
                value: report.clusterManager,
                icon: Icons.account_tree_outlined,
                color: AppHelpers.passPercentColor(report.passPercent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppPanel(
          title: 'Audit parameters',
          icon: Icons.fact_check_outlined,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.greyTint),
              dataRowMinHeight: 58,
              dataRowMaxHeight: 74,
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Parameter')),
                DataColumn(label: Text('Result')),
                DataColumn(label: Text('Remark')),
                DataColumn(label: Text('Evidence')),
              ],
              rows: report.parameters.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text('${item.index}')),
                    DataCell(SizedBox(width: 260, child: Text(item.name))),
                    DataCell(StatusPill(status: item.result ?? 'NA')),
                    DataCell(SizedBox(width: 280, child: Text(item.remark))),
                    DataCell(
                      item.imageUrl == null
                          ? Text('-', style: AppTextStyles.body12)
                          : const Icon(Icons.image_outlined),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        if (report.actionPlan != null) ...[
          const SizedBox(height: 16),
          AppPanel(
            title: 'Action plan',
            icon: Icons.checklist_rounded,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.greyTint),
                columns: const [
                  DataColumn(label: Text('Fail point')),
                  DataColumn(label: Text('Corrective action')),
                  DataColumn(label: Text('Owner')),
                  DataColumn(label: Text('Due date')),
                  DataColumn(label: Text('Status')),
                ],
                rows: report.actionPlan!.items.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(SizedBox(width: 220, child: Text(item.parameterName))),
                      DataCell(SizedBox(width: 260, child: Text(item.correctiveAction))),
                      DataCell(Text(item.responsiblePerson)),
                      DataCell(Text(AppDateUtils.formatDisplay(item.dueDate))),
                      DataCell(StatusPill(status: item.status)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
        if (_pdfPath != null) ...[
          const SizedBox(height: 16),
          AppPanel(
            title: 'PDF preview',
            icon: Icons.picture_as_pdf_outlined,
            child: SizedBox(
              height: 420,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: PDFView(filePath: _pdfPath!),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        AppPanel(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AppButton(
                label: 'Download PDF',
                icon: Icons.download_rounded,
                variant: AppButtonVariant.ghost,
                onPressed: () async {
                  final path = await ref
                      .read(reportServiceProvider)
                      .downloadReportPDF(widget.auditId);
                  setState(() => _pdfPath = path);
                  if (!context.mounted) return;
                  AppHelpers.showSuccessSnackbar(context, 'PDF ready for preview.');
                },
              ),
              AppButton(
                label: 'Share Link',
                icon: Icons.link_rounded,
                variant: AppButtonVariant.ghost,
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text:
                          '${ApiConstants.baseUrl}/report/${widget.auditId}',
                    ),
                  );
                  if (!context.mounted) return;
                  AppHelpers.showSuccessSnackbar(context, 'Report link copied.');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
