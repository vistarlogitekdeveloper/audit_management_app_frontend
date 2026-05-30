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
    final stats = AppHelpers.asStringMap(json['stats']) ?? {};
    final audits = AppHelpers.mapList(json['myAudits'], AuditorAudit.fromJson);
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

  /// Audit-sheet statuses that mean the owner has already acknowledged and
  /// so the row should never appear in the "Audits awaiting acknowledgement"
  /// panel — even if the backend's `awaitingAcknowledgement` list still
  /// carries it. Filtering here keeps the dashboards correct without
  /// waiting on a backend fix.
  ///
  /// Deliberately narrow: only `acknowledged` is filtered. An earlier
  /// version also dropped `closed` / `completed`, but those statuses
  /// overlap with audit-plan lifecycle values the backend sometimes
  /// surfaces on legitimately-awaiting rows — filtering them blanked the
  /// table.
  static const _ackedSheetStatuses = {'acknowledged'};

  /// Action-plan statuses that mean the plan is no longer awaiting the
  /// owner's attention — submitted moves it to the auditor's review,
  /// closed means it's done. "Open action plans" stays focused on plans
  /// the owner can still act on.
  static const _doneActionPlanStatuses = {
    'submitted',
    'in_review',
    'under_review',
    'closed',
    'completed',
  };

  factory OwnerDashboardModel.fromJson(Map<String, dynamic> json) {
    final stats = AppHelpers.asStringMap(json['stats']) ?? const {};
    final rawAudits = AppHelpers.mapList(
      json['awaitingAcknowledgement'] ?? json['auditsAwaiting'],
      OwnerAuditReview.fromJson,
    );
    final filteredAudits = rawAudits
        .where((a) => !_ackedSheetStatuses
            .contains((a.auditSheetStatus).toLowerCase()))
        .toList();
    final rawActionPlans =
        AppHelpers.mapList(json['actionPlans'], OwnerActionPlan.fromJson);
    final filteredActionPlans = rawActionPlans
        .where((p) =>
            !_doneActionPlanStatuses.contains((p.status).toLowerCase()))
        .toList();
    final backendAwaitingReview = AppHelpers.parseInt(stats['awaitingReview']);
    final backendActionPlanDue = AppHelpers.parseInt(stats['actionPlanDue']);
    return OwnerDashboardModel(
      // Reconcile the headline counters with the filtered lists so the
      // "Awaiting review" / "Action plans due" tiles can't disagree with
      // what's rendered below them. We never grow past what the backend
      // reported (rawAudits/rawActionPlans length is the ceiling).
      awaitingReview: filteredAudits.length < backendAwaitingReview
          ? filteredAudits.length
          : backendAwaitingReview,
      acknowledged: AppHelpers.parseInt(stats['acknowledged']),
      actionPlanDue: filteredActionPlans.length < backendActionPlanDue
          ? filteredActionPlans.length
          : backendActionPlanDue,
      lastPassPercent: AppHelpers.parseDouble(stats['lastPassPercent']),
      auditsAwaiting: filteredAudits,
      actionPlans: filteredActionPlans,
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
    this.auditSheetStatus = '',
  });

  final String id;
  final String project;
  final String auditor;
  final DateTime date;
  final double passPercent;
  final int failPoints;

  /// Lower-cased status of the underlying AuditSheet — `submitted` /
  /// `acknowledged` / `closed` / etc. Carried here so the dashboard model
  /// can drop already-acknowledged rows even if the backend still includes
  /// them in `awaitingAcknowledgement`.
  final String auditSheetStatus;

  factory OwnerAuditReview.fromJson(Map<String, dynamic> json) {
    // Backend `awaitingAcknowledgement` returns full AuditPlan rows with the
    // project + AuditSheet + auditor associations included. Older shapes used
    // flat fields like `passPercent` / `failPoints` — fall back to those.
    final projectMap = AppHelpers.asStringMap(json['project']);
    final sheetMap = AppHelpers.asStringMap(json['AuditSheet']);
    final auditorMap = AppHelpers.asStringMap(json['auditor']);

    final projectName = projectMap?['name']?.toString() ??
        (json['project'] is String ? json['project'] as String : '');
    final auditorName = auditorMap?['name']?.toString() ??
        (json['auditor'] is String ? json['auditor'] as String : '');
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
    final sheetStatus = (sheetMap?['status']?.toString() ??
            json['auditSheetStatus']?.toString() ??
            json['sheet_status']?.toString() ??
            '')
        .toLowerCase();

    return OwnerAuditReview(
      id: json['id']?.toString() ?? '',
      project: projectName,
      auditor: auditorName,
      date: auditDate,
      passPercent: passPercent,
      failPoints: failPoints,
      auditSheetStatus: sheetStatus,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project': project,
        'auditor': auditor,
        'date': date.toIso8601String(),
        'passPercent': passPercent,
        'failPoints': failPoints,
        'auditSheetStatus': auditSheetStatus,
      };
}

class OwnerActionPlan {
  const OwnerActionPlan({
    required this.id,
    required this.project,
    required this.failPoints,
    required this.dueDate,
    required this.daysRemaining,
    this.status = '',
  });

  final String id;
  final String project;
  final int failPoints;
  final DateTime dueDate;
  final int daysRemaining;

  /// Lower-cased status of the plan — `pending` / `submitted` / `closed`
  /// etc. Carried here so the dashboard model can drop plans that the
  /// owner has already submitted (and are now in the auditor's review
  /// queue) from the "Open action plans" panel.
  final String status;

  factory OwnerActionPlan.fromJson(Map<String, dynamic> json) {
    return OwnerActionPlan(
      id: json['id']?.toString() ?? '',
      project: json['project']?.toString() ?? '',
      failPoints: AppHelpers.parseInt(json['failPoints']),
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? '') ??
          DateTime.now(),
      daysRemaining: AppHelpers.parseInt(json['daysRemaining']),
      status: (json['status']?.toString() ?? '').toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project': project,
        'failPoints': failPoints,
        'dueDate': dueDate.toIso8601String(),
        'daysRemaining': daysRemaining,
        'status': status,
      };
}
