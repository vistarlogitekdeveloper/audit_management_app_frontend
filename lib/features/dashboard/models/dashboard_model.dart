import '../../../core/utils/helpers.dart';

class AdminDashboardModel {
  const AdminDashboardModel({
    required this.stats,
    required this.upcomingAudits,
    required this.clusterPassRates,
    required this.recentActivity,
    required this.allProjects,
  });

  final DashboardStats stats;
  final List<UpcomingAudit> upcomingAudits;
  final List<ClusterPassRate> clusterPassRates;
  final List<ActivityItem> recentActivity;
  final List<Project> allProjects;

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      stats: DashboardStats.fromJson(
        AppHelpers.asStringMap(json['stats']) ?? {},
      ),
      upcomingAudits:
          AppHelpers.mapList(json['upcomingAudits'], UpcomingAudit.fromJson),
      clusterPassRates:
          AppHelpers.mapList(json['clusterPassRates'], ClusterPassRate.fromJson),
      recentActivity:
          AppHelpers.mapList(json['recentActivity'], ActivityItem.fromJson),
      allProjects: AppHelpers.mapList(json['allProjects'], Project.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
        'stats': stats.toJson(),
        'upcomingAudits': upcomingAudits.map((e) => e.toJson()).toList(),
        'clusterPassRates': clusterPassRates.map((e) => e.toJson()).toList(),
        'recentActivity': recentActivity.map((e) => e.toJson()).toList(),
        'allProjects': allProjects.map((e) => e.toJson()).toList(),
      };
}

class DashboardStats {
  const DashboardStats({
    required this.totalPlanned,
    required this.completed,
    required this.pendingReview,
    required this.overdueActionPlans,
  });

  final int totalPlanned;
  final int completed;
  final int pendingReview;
  final int overdueActionPlans;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalPlanned: AppHelpers.parseInt(json['totalPlanned']),
      completed: AppHelpers.parseInt(json['completed']),
      pendingReview: AppHelpers.parseInt(json['pendingReview']),
      overdueActionPlans: AppHelpers.parseInt(json['overdueActionPlans']),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalPlanned': totalPlanned,
        'completed': completed,
        'pendingReview': pendingReview,
        'overdueActionPlans': overdueActionPlans,
      };
}

class UpcomingAudit {
  const UpcomingAudit({
    required this.id,
    required this.projectId,
    required this.auditorId,
    required this.auditDate,
    required this.scheduledDate,
    required this.location,
    required this.status,
    this.remarks,
  });

  final String id;
  final String projectId;
  final String auditorId;
  final DateTime auditDate;
  final DateTime scheduledDate;
  final String location;
  final String status;
  final String? remarks;

  factory UpcomingAudit.fromJson(Map<String, dynamic> json) {
    return UpcomingAudit(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      auditorId: json['auditor_id']?.toString() ?? '',
      auditDate: DateTime.tryParse(json['audit_date']?.toString() ?? '') ??
          DateTime.now(),
      scheduledDate:
          DateTime.tryParse(json['scheduled_date']?.toString() ?? '') ??
              DateTime.now(),
      location: json['location']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      remarks: json['remarks']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'auditor_id': auditorId,
        'audit_date': auditDate.toIso8601String(),
        'scheduled_date': scheduledDate.toIso8601String(),
        'location': location,
        'status': status,
        'remarks': remarks,
      };
}

class ClusterPassRate {
  const ClusterPassRate({
    required this.clusterId,
    required this.clusterName,
    required this.passRate,
  });

  final String clusterId;
  final String clusterName;
  final double passRate;

  factory ClusterPassRate.fromJson(Map<String, dynamic> json) {
    return ClusterPassRate(
      clusterId: json['cluster_id']?.toString() ?? '',
      clusterName: json['cluster_name']?.toString() ?? '',
      passRate: AppHelpers.parseDouble(json['pass_rate']),
    );
  }

  Map<String, dynamic> toJson() => {
        'cluster_id': clusterId,
        'cluster_name': clusterName,
        'pass_rate': passRate,
      };
}

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.title,
    required this.meta,
    required this.type,
  });

  final String id;
  final String title;
  final String meta;
  final String type;

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      meta: json['meta']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'meta': meta,
        'type': type,
      };
}

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.location,
    this.clientName,
    required this.isActive,
  });

  final String id;
  final String name;
  final String location;
  final String? clientName;
  final bool isActive;

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      clientName: json['client_name']?.toString(),
      isActive: AppHelpers.parseBool(json['is_active'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'client_name': clientName,
        'is_active': isActive,
      };
}
