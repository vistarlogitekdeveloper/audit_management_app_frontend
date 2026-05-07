class AuditPlanModel {
  const AuditPlanModel({
    required this.id,
    required this.projectName,
    required this.projectIncharge,
    required this.clusterManager,
    required this.auditorName,
    required this.auditDate,
    required this.location,
    required this.status,
    this.remarks = '',
  });

  final String id;
  final String projectName;
  final String projectIncharge;
  final String clusterManager;
  final String auditorName;
  final DateTime auditDate;
  final String location;
  final String status;
  final String remarks;

  // Extracts a name string from either a plain string or a nested user object
  // (backend sometimes returns {id, name, email, …} instead of a bare string).
  static String _nameFromNested(dynamic value) {
    if (value is Map) return value['name']?.toString() ?? '';
    return value?.toString() ?? '';
  }

  factory AuditPlanModel.fromJson(Map<String, dynamic> json) {
    // Handle nested response structure if present
    final data = json['auditPlan'] is Map<String, dynamic>
        ? json['auditPlan'] as Map<String, dynamic>
        : json;

    final id = data['id']?.toString() ??
        data['_id']?.toString() ??
        data['audit_plan_id']?.toString() ??
        data['auditPlanId']?.toString() ??
        '';

    return AuditPlanModel(
      id: id,
      projectName: _nameFromNested(
          data['project'] ??
          data['projectName'] ??
          data['project_name']),
      projectIncharge: _nameFromNested(
          data['projectIncharge'] ?? data['project_incharge']),
      clusterManager: _nameFromNested(
          data['clusterManager'] ??
          data['cluster_manager'] ??
          data['clusterManagerName'] ??
          data['cluster_manager_name']),
      auditorName: _nameFromNested(
          data['auditor'] ??
          data['auditorName'] ??
          data['auditor_name']),
      auditDate:
          DateTime.tryParse(
            data['auditDate']?.toString() ??
                data['audit_date']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      location: data['location']?.toString() ?? '',
      status: data['status']?.toString() ?? 'draft',
      remarks: data['remarks']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectName': projectName,
    'projectIncharge': projectIncharge,
    'clusterManager': clusterManager,
    'auditorName': auditorName,
    'auditDate': auditDate.toIso8601String(),
    'location': location,
    'status': status,
    'remarks': remarks,
  };
}

class ProjectLookupModel {
  const ProjectLookupModel({
    required this.id,
    required this.name,
    required this.inchargeId,
    required this.inchargeName,
    required this.inchargeEmail,
    required this.clusterManagerId,
    required this.clusterManagerName,
    required this.clusterManagerEmail,
    required this.location,
  });

  final String id;
  final String name;
  final String inchargeId;
  final String inchargeName;
  final String inchargeEmail;
  final String clusterManagerId;
  final String clusterManagerName;
  final String clusterManagerEmail;
  final String location;

  factory ProjectLookupModel.fromJson(
    Map<String, dynamic> json, {
    bool isFromLeadsApi = false,
  }) {
    if (isFromLeadsApi) {
      // Map from leads API response format
      return ProjectLookupModel(
        id: json['id']?.toString() ?? '',
        name: json['company_name']?.toString() ?? '',
        inchargeId: '',
        inchargeName: json['contact_person']?.toString() ?? '',
        inchargeEmail: json['email']?.toString() ?? '',
        clusterManagerId: '',
        clusterManagerName: '',
        clusterManagerEmail: '',
        location: json['project_location']?.toString() ?? '',
      );
    }
    // Map from regular API response format
    return ProjectLookupModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      inchargeId:
          json['project_incharge_id']?.toString() ??
          json['projectInchargeId']?.toString() ??
          '',
      inchargeName: json['projectIncharge']?.toString() ?? '',
      inchargeEmail: json['projectInchargeEmail']?.toString() ?? '',
      clusterManagerId:
          json['cluster_manager_id']?.toString() ??
          json['clusterManagerId']?.toString() ??
          '',
      clusterManagerName: json['clusterManager']?.toString() ?? '',
      clusterManagerEmail: json['clusterManagerEmail']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
    );
  }
}

class UserLookupModel {
  const UserLookupModel({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  String get label => email.isEmpty ? name : '$name · $email';

  factory UserLookupModel.fromJson(Map<String, dynamic> json) {
    return UserLookupModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}
