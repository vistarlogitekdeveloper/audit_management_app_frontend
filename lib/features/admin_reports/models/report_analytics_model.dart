import '../../../core/utils/helpers.dart';

/// Aggregated performance analytics for the Reports & Analytics section,
/// returned by `GET /reports/analytics` (respecting the same filters + role
/// scoping as the exports).
class ReportAnalytics {
  const ReportAnalytics({
    required this.overall,
    required this.projects,
    required this.clusters,
    required this.points,
    this.topProject,
    this.bottomProject,
    this.worstPoint,
  });

  final AnalyticsOverall overall;
  final List<GroupPerformance> projects;
  final List<GroupPerformance> clusters;

  /// Per audit-point pass/fail analysis, ranked worst-first (Pareto).
  final List<PointStat> points;
  final GroupPerformance? topProject;
  final GroupPerformance? bottomProject;
  final PointStat? worstPoint;

  factory ReportAnalytics.fromJson(Map<String, dynamic> json) {
    return ReportAnalytics(
      overall:
          AnalyticsOverall.fromJson(AppHelpers.asStringMap(json['overall']) ?? {}),
      projects: AppHelpers.mapList(json['projects'], GroupPerformance.fromJson),
      clusters: AppHelpers.mapList(json['clusters'], GroupPerformance.fromJson),
      points: AppHelpers.mapList(json['points'], PointStat.fromJson),
      topProject: json['topProject'] is Map<String, dynamic>
          ? GroupPerformance.fromJson(json['topProject'] as Map<String, dynamic>)
          : null,
      bottomProject: json['bottomProject'] is Map<String, dynamic>
          ? GroupPerformance.fromJson(
              json['bottomProject'] as Map<String, dynamic>)
          : null,
      worstPoint: json['worstPoint'] is Map<String, dynamic>
          ? PointStat.fromJson(json['worstPoint'] as Map<String, dynamic>)
          : null,
    );
  }

  static const empty = ReportAnalytics(
    overall: AnalyticsOverall.zero,
    projects: [],
    clusters: [],
    points: [],
  );
}

/// One audit point aggregated across all audits in scope — how often it passes
/// vs fails, with its Pareto rank and cumulative share of all failures.
class PointStat {
  const PointStat({
    required this.name,
    required this.pass,
    required this.fail,
    required this.na,
    required this.scored,
    required this.failPercent,
    required this.passPercent,
    required this.rank,
    required this.cumulativePercent,
  });

  final String name;
  final int pass;
  final int fail;
  final int na;
  final int scored;
  final double failPercent;
  final double passPercent;
  final int rank;
  final double cumulativePercent;

  factory PointStat.fromJson(Map<String, dynamic> json) {
    return PointStat(
      name: json['name']?.toString() ?? '(Unnamed point)',
      pass: AppHelpers.parseInt(json['pass']),
      fail: AppHelpers.parseInt(json['fail']),
      na: AppHelpers.parseInt(json['na']),
      scored: AppHelpers.parseInt(json['scored']),
      failPercent: AppHelpers.parseDouble(json['failPercent']),
      passPercent: AppHelpers.parseDouble(json['passPercent']),
      rank: AppHelpers.parseInt(json['rank']),
      cumulativePercent: AppHelpers.parseDouble(json['cumulativePercent']),
    );
  }
}

class AnalyticsOverall {
  const AnalyticsOverall({
    required this.totalAudits,
    required this.completed,
    required this.submitted,
    required this.acknowledged,
    required this.totalPass,
    required this.totalFail,
    required this.totalAudited,
    required this.avgPassPercent,
  });

  final int totalAudits;
  final int completed;
  final int submitted;
  final int acknowledged;
  final int totalPass;
  final int totalFail;
  final int totalAudited;
  final double avgPassPercent;

  static const zero = AnalyticsOverall(
    totalAudits: 0,
    completed: 0,
    submitted: 0,
    acknowledged: 0,
    totalPass: 0,
    totalFail: 0,
    totalAudited: 0,
    avgPassPercent: 0,
  );

  factory AnalyticsOverall.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverall(
      totalAudits: AppHelpers.parseInt(json['totalAudits']),
      completed: AppHelpers.parseInt(json['completed']),
      submitted: AppHelpers.parseInt(json['submitted']),
      acknowledged: AppHelpers.parseInt(json['acknowledged']),
      totalPass: AppHelpers.parseInt(json['totalPass']),
      totalFail: AppHelpers.parseInt(json['totalFail']),
      totalAudited: AppHelpers.parseInt(json['totalAudited']),
      avgPassPercent: AppHelpers.parseDouble(json['avgPassPercent']),
    );
  }
}

/// One ranked group (a project or a cluster) in the performance list.
class GroupPerformance {
  const GroupPerformance({
    required this.id,
    required this.name,
    required this.location,
    required this.audits,
    required this.passPercent,
    required this.totalPass,
    required this.totalFail,
    required this.totalAudited,
    required this.lastAuditDate,
  });

  final String id;
  final String name;
  final String location;
  final int audits;
  final double passPercent;
  final int totalPass;
  final int totalFail;
  final int totalAudited;
  final String lastAuditDate;

  factory GroupPerformance.fromJson(Map<String, dynamic> json) {
    return GroupPerformance(
      // Backend keys differ per group: project uses projectId/project,
      // cluster uses clusterId/cluster.
      id: json['projectId']?.toString() ??
          json['clusterId']?.toString() ??
          '',
      name: json['project']?.toString() ??
          json['cluster']?.toString() ??
          '(Unknown)',
      location: json['location']?.toString() ?? '',
      audits: AppHelpers.parseInt(json['audits']),
      passPercent: AppHelpers.parseDouble(json['passPercent']),
      totalPass: AppHelpers.parseInt(json['totalPass']),
      totalFail: AppHelpers.parseInt(json['totalFail']),
      totalAudited: AppHelpers.parseInt(json['totalAudited']),
      lastAuditDate: json['lastAuditDate']?.toString() ?? '',
    );
  }
}
