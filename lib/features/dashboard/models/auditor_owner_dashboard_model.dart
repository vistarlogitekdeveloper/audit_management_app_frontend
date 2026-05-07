import '../../../core/utils/helpers.dart';

class AuditorDashboardModel {
  const AuditorDashboardModel({
    required this.assignedCount,
    required this.pendingCount,
    required this.completedCount,
    required this.upcomingCount,
    required this.avgPassRate,
    required this.audits,
  });

  final int assignedCount;
  final int pendingCount;
  final int completedCount;
  final int upcomingCount;
  final double avgPassRate;
  final List<AuditorAudit> audits;

  factory AuditorDashboardModel.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final audits = (json['myAudits'] as List?)
            ?.map((item) => AuditorAudit.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];
    // Compute upcomingCount from audits if not provided by backend
    final backendUpcoming = stats['upcoming'] == null
        ? null
        : AppHelpers.parseInt(stats['upcoming']);
    final computedUpcoming = backendUpcoming ??
        audits.where((a) {
          final sheet = (a.auditSheetStatus ?? '').toLowerCase();
          final isSubmitted = ['submitted', 'acknowledged', 'completed'].contains(sheet);
          return !isSubmitted && a.date.isAfter(DateTime.now());
        }).length;
    return AuditorDashboardModel(
      assignedCount: AppHelpers.parseInt(stats['assignedToMe']),
      pendingCount: AppHelpers.parseInt(stats['pending']),
      completedCount: AppHelpers.parseInt(stats['completed']),
      upcomingCount: computedUpcoming,
      avgPassRate: AppHelpers.parseDouble(stats['avgPassRate']),
      audits: audits,
    );
  }

  Map<String, dynamic> toJson() => {
        'assignedCount': assignedCount,
        'pendingCount': pendingCount,
        'completedCount': completedCount,
        'upcomingCount': upcomingCount,
        'avgPassRate': avgPassRate,
        'audits': audits.map((e) => e.toJson()).toList(),
      };
}

class AuditorAudit {
  const AuditorAudit({
    required this.id,
    required this.project,
    required this.location,
    required this.date,
    required this.status,
    this.projectManager,
    this.clusterManager,
    this.auditSheetStatus,
    this.auditSheetSubmittedAt,
    this.passPercent,
  });

  final String id;
  final String project;
  final String location;
  final DateTime date;
  final String status;              // audit plan status e.g. "released"
  final String? projectManager;     // from project.project_manager or similar
  final String? clusterManager;     // from project.cluster_manager
  final String? auditSheetStatus;   // e.g. "not_started", "submitted", "completed"
  final DateTime? auditSheetSubmittedAt;
  final double? passPercent;

  /// Derived display status for the auditor
  String get displayStatus {
    final sheet = (auditSheetStatus ?? '').toLowerCase();
    if (['acknowledged'].contains(sheet)) return 'acknowledged';
    if (['submitted', 'under_review'].contains(sheet)) return 'submitted';
    final plan = status.toLowerCase();
    if (['completed', 'closed'].contains(plan)) return 'completed';
    if (date.isAfter(DateTime.now())) return 'upcoming';
    if (['released', 'assigned', 'in progress', 'scheduled', 'in_progress'].contains(plan)) {
      return sheet == 'draft' ? 'in_progress' : 'pending';
    }
    return plan;
  }

  factory AuditorAudit.fromJson(Map<String, dynamic> json) {
    final projectData = json['project'] is Map ? json['project'] as Map : null;
    final sheetData = json['AuditSheet'] is Map ? json['AuditSheet'] as Map : null;
    return AuditorAudit(
      id: json['id']?.toString() ?? '',
      project: projectData != null 
          ? projectData['name']?.toString() ?? '' 
          : json['project']?.toString() ?? '',
      location: projectData != null 
          ? projectData['location']?.toString() ?? '' 
          : json['location']?.toString() ?? '',
      date: DateTime.tryParse(json['audit_date']?.toString() ?? json['date']?.toString() ?? '') ??
          DateTime.now(),
      status: json['status']?.toString() ?? '',
      projectManager: projectData != null
          ? (projectData['project_manager']?.toString() ?? projectData['manager']?.toString())
          : json['projectManager']?.toString(),
      clusterManager: projectData != null
          ? (projectData['cluster_manager']?.toString() ?? projectData['clusterManager']?.toString())
          : json['clusterManager']?.toString(),
      auditSheetStatus: sheetData != null 
          ? sheetData['status']?.toString() 
          : null,
      auditSheetSubmittedAt: sheetData != null && sheetData['submitted_at'] != null
          ? DateTime.tryParse(sheetData['submitted_at'].toString())
          : null,
      passPercent: sheetData != null && sheetData['pass_percent'] != null
          ? AppHelpers.parseDouble(sheetData['pass_percent'])
          : (json['pass_percent'] == null
              ? null
              : AppHelpers.parseDouble(json['pass_percent'])),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project': project,
        'location': location,
        'date': date.toIso8601String(),
        'status': status,
        'projectManager': projectManager,
        'clusterManager': clusterManager,
        'auditSheetStatus': auditSheetStatus,
        'passPercent': passPercent,
      };
}

class OwnerDashboardModel {
  const OwnerDashboardModel({
    required this.awaitingReview,
    required this.acknowledged,
    required this.actionPlanDue,
    required this.lastPassPercent,
    required this.auditsAwaiting,
    required this.actionPlans,
  });

  final int awaitingReview;
  final int acknowledged;
  final int actionPlanDue;
  final double lastPassPercent;
  final List<OwnerAuditReview> auditsAwaiting;
  final List<OwnerActionPlan> actionPlans;

  factory OwnerDashboardModel.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? const {};
    final awaiting = (json['awaitingAcknowledgement'] ?? json['auditsAwaiting'])
        as List?;
    return OwnerDashboardModel(
      awaitingReview: AppHelpers.parseInt(stats['awaitingReview']),
      acknowledged: AppHelpers.parseInt(stats['acknowledged']),
      actionPlanDue: AppHelpers.parseInt(stats['actionPlanDue']),
      lastPassPercent: AppHelpers.parseDouble(stats['lastPassPercent']),
      auditsAwaiting: awaiting
              ?.map((item) =>
                  OwnerAuditReview.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      actionPlans: (json['actionPlans'] as List?)
              ?.map((item) =>
                  OwnerActionPlan.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'awaitingReview': awaitingReview,
        'acknowledged': acknowledged,
        'actionPlanDue': actionPlanDue,
        'lastPassPercent': lastPassPercent,
        'auditsAwaiting':
            auditsAwaiting.map((e) => e.toJson()).toList(),
        'actionPlans': actionPlans.map((e) => e.toJson()).toList(),
      };
}

class OwnerAuditReview {
  const OwnerAuditReview({
    required this.id,
    required this.project,
    required this.auditor,
    required this.date,
    required this.passPercent,
    required this.failPoints,
  });

  final String id;
  final String project;
  final String auditor;
  final DateTime date;
  final double passPercent;
  final int failPoints;

  factory OwnerAuditReview.fromJson(Map<String, dynamic> json) {
    // Backend `awaitingAcknowledgement` returns full AuditPlan rows with the
    // project + AuditSheet + auditor associations included. Older shapes used
    // flat fields like `passPercent` / `failPoints` — fall back to those.
    final projectMap =
        json['project'] is Map<String, dynamic> ? json['project'] as Map<String, dynamic> : null;
    final sheetMap =
        json['AuditSheet'] is Map<String, dynamic> ? json['AuditSheet'] as Map<String, dynamic> : null;
    final auditorMap =
        json['auditor'] is Map<String, dynamic> ? json['auditor'] as Map<String, dynamic> : null;

    final projectName = projectMap?['name']?.toString() ??
        (json['project'] is String ? json['project'] as String : '') ??
        '';
    final auditorName = auditorMap?['name']?.toString() ??
        (json['auditor'] is String ? json['auditor'] as String : '') ??
        '';
    final auditDate = DateTime.tryParse(
          json['audit_date']?.toString() ?? json['date']?.toString() ?? '',
        ) ??
        DateTime.now();
    final passPercent = sheetMap != null && sheetMap['pass_percent'] != null
        ? AppHelpers.parseDouble(sheetMap['pass_percent'])
        : AppHelpers.parseDouble(json['passPercent']);
    final failPoints = sheetMap != null && sheetMap['total_fail'] != null
        ? AppHelpers.parseInt(sheetMap['total_fail'])
        : AppHelpers.parseInt(json['failPoints']);

    return OwnerAuditReview(
      id: json['id']?.toString() ?? '',
      project: projectName,
      auditor: auditorName,
      date: auditDate,
      passPercent: passPercent,
      failPoints: failPoints,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project': project,
        'auditor': auditor,
        'date': date.toIso8601String(),
        'passPercent': passPercent,
        'failPoints': failPoints,
      };
}

class OwnerActionPlan {
  const OwnerActionPlan({
    required this.id,
    required this.project,
    required this.failPoints,
    required this.dueDate,
    required this.daysRemaining,
  });

  final String id;
  final String project;
  final int failPoints;
  final DateTime dueDate;
  final int daysRemaining;

  factory OwnerActionPlan.fromJson(Map<String, dynamic> json) {
    return OwnerActionPlan(
      id: json['id']?.toString() ?? '',
      project: json['project']?.toString() ?? '',
      failPoints: AppHelpers.parseInt(json['failPoints']),
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? '') ??
          DateTime.now(),
      daysRemaining: AppHelpers.parseInt(json['daysRemaining']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project': project,
        'failPoints': failPoints,
        'dueDate': dueDate.toIso8601String(),
        'daysRemaining': daysRemaining,
      };
}
