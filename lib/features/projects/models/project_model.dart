import '../../../core/utils/helpers.dart';

class ProjectAdminModel {
  const ProjectAdminModel({
    required this.id,
    required this.name,
    required this.location,
    required this.clientName,
    required this.inchargeId,
    required this.inchargeName,
    required this.clusterManagerId,
    required this.clusterManagerName,
    required this.isActive,
  });

  final String id;
  final String name;
  final String location;
  final String clientName;
  final String inchargeId;
  final String inchargeName;
  final String clusterManagerId;
  final String clusterManagerName;
  final bool isActive;

  factory ProjectAdminModel.fromJson(Map<String, dynamic> json) {
    final incharge = json['incharge'] as Map<String, dynamic>?;
    final cluster = json['clusterManager'] as Map<String, dynamic>?;
    return ProjectAdminModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? '',
      inchargeId: incharge?['id']?.toString() ??
          json['project_incharge_id']?.toString() ??
          '',
      inchargeName: incharge?['name']?.toString() ?? '',
      clusterManagerId: cluster?['id']?.toString() ??
          json['cluster_manager_id']?.toString() ??
          '',
      clusterManagerName: cluster?['name']?.toString() ?? '',
      isActive: AppHelpers.parseBool(json['is_active'], fallback: true),
    );
  }

  ProjectAdminModel copyWith({bool? isActive}) {
    return ProjectAdminModel(
      id: id,
      name: name,
      location: location,
      clientName: clientName,
      inchargeId: inchargeId,
      inchargeName: inchargeName,
      clusterManagerId: clusterManagerId,
      clusterManagerName: clusterManagerName,
      isActive: isActive ?? this.isActive,
    );
  }
}
