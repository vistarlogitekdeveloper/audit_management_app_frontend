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
  });

  final String id;
  final String auditSheetId;
  final List<ActionItemModel> items;
  final DateTime dueDate;
  final String status;
  final DateTime? submittedAt;
  final int? daysRemaining;

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
    );
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
    this.auditorRemark = '',
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
  final String auditorRemark;

  ActionItemModel copyWith({
    String? id,
    String? auditParameterId,
    String? parameterName,
    String? correctiveAction,
    String? responsiblePerson,
    DateTime? dueDate,
    String? status,
    String? auditorRemark,
  }) {
    return ActionItemModel(
      id: id ?? this.id,
      auditParameterId: auditParameterId ?? this.auditParameterId,
      parameterName: parameterName ?? this.parameterName,
      correctiveAction: correctiveAction ?? this.correctiveAction,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      auditorRemark: auditorRemark ?? this.auditorRemark,
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
      auditorRemark: json['auditorRemark']?.toString() ?? '',
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
