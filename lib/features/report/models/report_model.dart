import '../../../core/utils/helpers.dart';
import '../../action_plan/models/action_plan_model.dart';
import '../../audit_sheet/models/audit_parameter_model.dart';

class ReportModel {
  const ReportModel({
    required this.auditId,
    required this.projectName,
    required this.auditorName,
    required this.date,
    required this.location,
    required this.clusterManager,
    required this.totalAudited,
    required this.passCount,
    required this.failCount,
    required this.passPercent,
    required this.parameters,
    this.actionPlan,
  });

  final String auditId;
  final String projectName;
  final String auditorName;
  final DateTime date;
  final String location;
  final String clusterManager;
  final int totalAudited;
  final int passCount;
  final int failCount;
  final double passPercent;
  final List<AuditParameterModel> parameters;
  final ActionPlanModel? actionPlan;

  /// Parses the report payload returned by `GET /api/reports/:auditPlanId`.
  ///
  /// The backend returns a nested shape:
  /// ```
  /// {
  ///   auditPlan:   { id, audit_date, location, status },
  ///   project:     { name, location, clusterManager: { name, ... } },
  ///   auditor:     { name, ... },
  ///   auditSheet:  { total_audited, total_pass, total_fail, pass_percent,
  ///                  parameters: [{ param_index, param_name, result, remark, image_url }] },
  ///   actionPlan:  { id, due_date, items: [...] } | null
  /// }
  /// ```
  /// We also tolerate the older flat shape (legacy `demo-audit` route) so
  /// the demo path doesn't regress.
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    // ── Detect demo / flat shape first ─────────────────────────────────
    if (json['parameters'] is List &&
        json['auditPlan'] == null &&
        json['auditSheet'] == null) {
      return ReportModel(
        auditId: json['auditId']?.toString() ?? '',
        projectName: json['projectName']?.toString() ?? '',
        auditorName: json['auditorName']?.toString() ?? '',
        date: DateTime.tryParse(json['date']?.toString() ?? '') ??
            DateTime.now(),
        location: json['location']?.toString() ?? '',
        clusterManager: json['clusterManager']?.toString() ?? '',
        totalAudited: AppHelpers.parseInt(json['totalAudited']),
        passCount: AppHelpers.parseInt(json['passCount']),
        failCount: AppHelpers.parseInt(json['failCount']),
        passPercent: AppHelpers.parseDouble(json['passPercent']),
        parameters: AppHelpers.mapList(
          json['parameters'],
          AuditParameterModel.fromJson,
        ),
        actionPlan: AppHelpers.asStringMap(json['actionPlan']) == null
            ? null
            : ActionPlanModel.fromJson(
                AppHelpers.asStringMap(json['actionPlan'])!),
      );
    }

    // ── Production / nested shape ───────────────────────────────────────
    final auditPlan = AppHelpers.asStringMap(json['auditPlan']) ?? const {};
    final project = AppHelpers.asStringMap(json['project']) ?? const {};
    final auditor = AppHelpers.asStringMap(json['auditor']) ?? const {};
    final sheet = AppHelpers.asStringMap(json['auditSheet']) ?? const {};
    // The cluster manager comes from project.clusterManager (Sequelize
    // association alias) but some payloads put it at the top level — and the
    // legacy/flat shape sends it as a plain name string.
    final clusterManager = AppHelpers.asStringMap(project['clusterManager']) ??
        AppHelpers.asStringMap(json['clusterManager']) ??
        const {};
    final actionPlanJson = AppHelpers.asStringMap(json['actionPlan']);

    return ReportModel(
      auditId: auditPlan['id']?.toString() ??
          json['auditId']?.toString() ??
          '',
      projectName: project['name']?.toString() ??
          json['projectName']?.toString() ??
          '',
      auditorName: auditor['name']?.toString() ??
          json['auditorName']?.toString() ??
          '',
      date: DateTime.tryParse(
            auditPlan['audit_date']?.toString() ??
                json['date']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      location: auditPlan['location']?.toString() ??
          project['location']?.toString() ??
          json['location']?.toString() ??
          '',
      clusterManager: clusterManager['name']?.toString() ??
          json['clusterManager']?.toString() ??
          '',
      totalAudited: AppHelpers.parseInt(
        sheet['total_audited'] ?? json['totalAudited'],
      ),
      passCount: AppHelpers.parseInt(
        sheet['total_pass'] ?? json['passCount'],
      ),
      failCount: AppHelpers.parseInt(
        sheet['total_fail'] ?? json['failCount'],
      ),
      passPercent: AppHelpers.parseDouble(
        sheet['pass_percent'] ?? json['passPercent'],
      ),
      parameters: AppHelpers.mapList(
        sheet['parameters'] ?? json['parameters'],
        AuditParameterModel.fromJson,
      ),
      actionPlan:
          actionPlanJson == null ? null : ActionPlanModel.fromJson(actionPlanJson),
    );
  }
}
