import '../../../core/constants/app_constants.dart';
import 'audit_parameter_model.dart';

class AuditSheetModel {
  const AuditSheetModel({
    required this.id,
    required this.auditPlanId,
    required this.projectName,
    required this.auditorName,
    required this.location,
    required this.auditDate,
    required this.parameters,
    this.status = AppConstants.statusDraft,
    this.submittedAt,
    this.acknowledgedAt,
  });

  final String id;
  final String auditPlanId;
  final String projectName;
  final String auditorName;
  final String location;
  final DateTime auditDate;
  final List<AuditParameterModel> parameters;
  final String status;
  final DateTime? submittedAt;
  final DateTime? acknowledgedAt;

  AuditSheetModel copyWith({
    String? id,
    String? auditPlanId,
    String? projectName,
    String? auditorName,
    String? location,
    DateTime? auditDate,
    List<AuditParameterModel>? parameters,
    String? status,
    DateTime? submittedAt,
    DateTime? acknowledgedAt,
  }) {
    return AuditSheetModel(
      id: id ?? this.id,
      auditPlanId: auditPlanId ?? this.auditPlanId,
      projectName: projectName ?? this.projectName,
      auditorName: auditorName ?? this.auditorName,
      location: location ?? this.location,
      auditDate: auditDate ?? this.auditDate,
      parameters: parameters ?? this.parameters,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }

  factory AuditSheetModel.fromJson(Map<String, dynamic> json) {
    final auditPlan = json['AuditPlan'] as Map<String, dynamic>?;
    final project = auditPlan?['project'] as Map<String, dynamic>?;
    final auditor = auditPlan?['auditor'] as Map<String, dynamic>?;

    return AuditSheetModel(
      id: json['id']?.toString() ?? '',
      auditPlanId:
          json['auditPlanId']?.toString() ??
          json['audit_plan_id']?.toString() ??
          auditPlan?['id']?.toString() ??
          '',
      projectName:
          json['projectName']?.toString() ?? project?['name']?.toString() ?? '',
      auditorName:
          json['auditorName']?.toString() ?? auditor?['name']?.toString() ?? '',
      location:
          json['location']?.toString() ??
          auditPlan?['location']?.toString() ??
          project?['location']?.toString() ??
          '',
      auditDate:
          DateTime.tryParse(
            json['auditDate']?.toString() ??
                auditPlan?['audit_date']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      parameters:
          (json['parameters'] as List<dynamic>? ?? [])
              .map(
                (item) =>
                    AuditParameterModel.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      status: json['status']?.toString() ?? AppConstants.statusDraft,
      submittedAt: DateTime.tryParse(
        json['submittedAt']?.toString() ??
            json['submitted_at']?.toString() ??
            '',
      ),
      acknowledgedAt: DateTime.tryParse(
        json['acknowledgedAt']?.toString() ??
            json['acknowledged_at']?.toString() ??
            '',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'auditPlanId': auditPlanId,
    'projectName': projectName,
    'auditorName': auditorName,
    'location': location,
    'auditDate': auditDate.toIso8601String(),
    'parameters': parameters.map((item) => item.toJson()).toList(),
    'status': status,
    'submittedAt': submittedAt?.toIso8601String(),
    'acknowledgedAt': acknowledgedAt?.toIso8601String(),
  };
}

class AuditRowState {
  const AuditRowState({this.result, this.remark = '', this.imagePath});

  final String? result;
  final String remark;
  final String? imagePath;

  AuditRowState copyWith({String? result, String? remark, String? imagePath}) {
    return AuditRowState(
      result: result ?? this.result,
      remark: remark ?? this.remark,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson(int index, String parameterName) => {
    'index': index,
    'name': parameterName,
    'result': result,
    'remark': remark,
    'imageUrl': imagePath,
  };
}
