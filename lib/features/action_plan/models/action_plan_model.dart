import '../../../core/utils/helpers.dart';

class ActionPlanModel {
  const ActionPlanModel({
    required this.id,
    required this.auditSheetId,
    required this.items,
    required this.dueDate,
    this.status = 'pending',
    this.submittedAt,
    this.daysRemaining,
    this.closeRemark = '',
    this.closedAt,
    this.closedBy,
  });

  final String id;
  final String auditSheetId;
  final List<ActionItemModel> items;
  final DateTime dueDate;
  final String status;
  final DateTime? submittedAt;
  final int? daysRemaining;

  /// Auditor's optional note left when closing the plan.
  final String closeRemark;

  /// When the auditor closed the plan (null until closed).
  final DateTime? closedAt;

  /// Auditor who closed the plan, if surfaced by the backend.
  final ReviewerRef? closedBy;

  bool get isClosed => status.toLowerCase() == 'closed' || closedAt != null;

  /// True when every item is review_status = 'approved' — i.e. the plan is
  /// ready for the auditor to close. Mirrors the backend's
  /// is_review_complete flag (used for the per-plan summary), with a local
  /// fallback in case the response doesn't include it.
  bool get isReviewComplete {
    if (items.isEmpty) return false;
    return items.every((i) => i.reviewStatus == 'approved');
  }

  factory ActionPlanModel.fromJson(Map<String, dynamic> json) {
    return ActionPlanModel(
      id: json['id']?.toString() ?? '',
      auditSheetId: json['audit_sheet_id']?.toString() ??
          json['auditSheetId']?.toString() ??
          json['auditId']?.toString() ??
          '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => ActionItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      dueDate: DateTime.tryParse(
            json['due_date']?.toString() ??
                json['dueDate']?.toString() ??
                '',
          ) ??
          DateTime.now().add(const Duration(days: 8)),
      status: json['status']?.toString() ?? 'pending',
      submittedAt: DateTime.tryParse(
        json['submitted_at']?.toString() ??
            json['submittedAt']?.toString() ??
            '',
      ),
      daysRemaining: json['daysRemaining'] == null
          ? null
          : AppHelpers.parseInt(json['daysRemaining']),
      closeRemark: json['close_remark']?.toString() ??
          json['closeRemark']?.toString() ??
          '',
      closedAt: DateTime.tryParse(
        json['closed_at']?.toString() ?? json['closedAt']?.toString() ?? '',
      ),
      closedBy: ReviewerRef.fromAny(json['closed_by'] ?? json['closedBy']),
    );
  }
}

/// Lightweight user reference returned by the backend for review / close
/// audit trail (reviewed_by, closed_by). Carries just an id + name; the
/// backend may also send the raw id string instead of a nested object, so
/// [fromAny] handles both.
class ReviewerRef {
  const ReviewerRef({required this.id, required this.name});

  final String id;
  final String name;

  static ReviewerRef? fromAny(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      final id = raw['id']?.toString() ?? '';
      final name = raw['name']?.toString() ?? '';
      if (id.isEmpty && name.isEmpty) return null;
      return ReviewerRef(id: id, name: name);
    }
    final id = raw.toString();
    if (id.isEmpty) return null;
    return ReviewerRef(id: id, name: '');
  }
}

class ActionItemModel {
  const ActionItemModel({
    this.id,
    required this.auditParameterId,
    required this.parameterName,
    required this.correctiveAction,
    required this.responsiblePerson,
    required this.dueDate,
    required this.status,
    this.auditObservation = '',
    this.auditorRemark = '',
    this.reviewStatus = 'pending',
    this.reviewedBy,
    this.reviewedAt,
  });

  /// Backend ActionItem id (null for items not yet persisted).
  final String? id;

  /// FK to the AuditParameter this item corrects. Required by backend.
  final String auditParameterId;

  final String parameterName;
  final String correctiveAction;
  final String responsiblePerson;
  final DateTime dueDate;

  /// Title-Case for the dropdown UI ("Open" / "In Progress" / "Closed").
  final String status;

  /// The auditor's original observation from the audit sheet (the `remark`
  /// they typed against this parameter when scoring it fail). Lives at
  /// `parameter.remark` on the API response. Distinct from [auditorRemark],
  /// which is the auditor's later note when *reviewing* the owner's
  /// corrective action. Surfaced on the Action Plan screen so the owner
  /// sees what the auditor flagged without having to open the audit sheet.
  final String auditObservation;

  /// Free-form note left by the auditor when reviewing the item. Required
  /// when the auditor rejects; optional when approved.
  final String auditorRemark;

  /// Auditor's verdict — 'pending' (default), 'approved', or 'rejected'.
  /// Backend resets this to 'pending' when the owner edits a rejected item.
  final String reviewStatus;

  /// Auditor who set the current reviewStatus (null when never reviewed or
  /// after a reset).
  final ReviewerRef? reviewedBy;

  /// When the auditor set the current reviewStatus.
  final DateTime? reviewedAt;

  bool get isApproved => reviewStatus == 'approved';
  bool get isRejected => reviewStatus == 'rejected';

  ActionItemModel copyWith({
    String? id,
    String? auditParameterId,
    String? parameterName,
    String? correctiveAction,
    String? responsiblePerson,
    DateTime? dueDate,
    String? status,
    String? auditObservation,
    String? auditorRemark,
    String? reviewStatus,
    ReviewerRef? reviewedBy,
    DateTime? reviewedAt,
  }) {
    return ActionItemModel(
      id: id ?? this.id,
      auditParameterId: auditParameterId ?? this.auditParameterId,
      parameterName: parameterName ?? this.parameterName,
      correctiveAction: correctiveAction ?? this.correctiveAction,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      auditObservation: auditObservation ?? this.auditObservation,
      auditorRemark: auditorRemark ?? this.auditorRemark,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  factory ActionItemModel.fromJson(Map<String, dynamic> json) {
    final parameter = json['parameter'] is Map<String, dynamic>
        ? json['parameter'] as Map<String, dynamic>
        : null;
    return ActionItemModel(
      id: json['id']?.toString(),
      auditParameterId: json['audit_parameter_id']?.toString() ??
          json['auditParameterId']?.toString() ??
          parameter?['id']?.toString() ??
          '',
      parameterName: json['fail_point']?.toString() ??
          json['parameterName']?.toString() ??
          parameter?['param_name']?.toString() ??
          '',
      correctiveAction: json['corrective_action']?.toString() ??
          json['correctiveAction']?.toString() ??
          '',
      responsiblePerson: json['responsible_person']?.toString() ??
          json['responsiblePerson']?.toString() ??
          '',
      dueDate: DateTime.tryParse(
            json['due_date']?.toString() ??
                json['dueDate']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      status: _statusToDisplay(
        json['status']?.toString() ?? 'open',
      ),
      auditObservation: parameter?['remark']?.toString() ?? '',
      auditorRemark: json['auditor_remark']?.toString() ??
          json['auditorRemark']?.toString() ??
          '',
      reviewStatus: (json['review_status']?.toString() ??
              json['reviewStatus']?.toString() ??
              'pending')
          .toLowerCase(),
      reviewedBy: ReviewerRef.fromAny(json['reviewed_by'] ?? json['reviewedBy']),
      reviewedAt: DateTime.tryParse(
        json['reviewed_at']?.toString() ?? json['reviewedAt']?.toString() ?? '',
      ),
    );
  }

  /// Convert backend snake_case status to Title-Case for the dropdown.
  static String _statusToDisplay(String backendStatus) {
    switch (backendStatus.toLowerCase()) {
      case 'in_progress':
        return 'In Progress';
      case 'closed':
        return 'Closed';
      case 'open':
      default:
        return 'Open';
    }
  }

  /// Convert UI Title-Case status to backend snake_case for sending.
  String get statusForApi {
    switch (status.toLowerCase()) {
      case 'in progress':
        return 'in_progress';
      case 'closed':
        return 'closed';
      case 'open':
      default:
        return 'open';
    }
  }
}
