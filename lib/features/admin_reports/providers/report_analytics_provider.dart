import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/report_analytics_model.dart';

/// Immutable filter key for the analytics fetch. Value equality lets the
/// [FutureProvider.family] cache per unique filter set and re-fetch when any
/// filter changes.
class AnalyticsQuery {
  const AnalyticsQuery({
    this.fromDate,
    this.toDate,
    this.projectId,
    this.clusterManagerId,
    this.status,
  });

  final String? fromDate;
  final String? toDate;
  final String? projectId;
  final String? clusterManagerId;
  final String? status;

  Map<String, dynamic> toQuery() => <String, dynamic>{
        if (fromDate != null && fromDate!.isNotEmpty) 'from_date': fromDate,
        if (toDate != null && toDate!.isNotEmpty) 'to_date': toDate,
        if (projectId != null && projectId!.isNotEmpty) 'project_id': projectId,
        if (clusterManagerId != null && clusterManagerId!.isNotEmpty)
          'cluster_manager_id': clusterManagerId,
        if (status != null && status!.isNotEmpty && status != 'all')
          'status': status,
      };

  @override
  bool operator ==(Object other) =>
      other is AnalyticsQuery &&
      other.fromDate == fromDate &&
      other.toDate == toDate &&
      other.projectId == projectId &&
      other.clusterManagerId == clusterManagerId &&
      other.status == status;

  @override
  int get hashCode =>
      Object.hash(fromDate, toDate, projectId, clusterManagerId, status);
}

class ReportAnalyticsService {
  ReportAnalyticsService(this._api);

  final ApiService _api;

  Future<ReportAnalytics> fetch(AnalyticsQuery query) async {
    final response = await _api.get(
      ApiConstants.reportAnalytics,
      queryParameters: query.toQuery(),
    );
    return ReportAnalytics.fromJson(_api.extractObject(response));
  }
}

final reportAnalyticsServiceProvider = Provider<ReportAnalyticsService>(
  (ref) => ReportAnalyticsService(ref.watch(apiServiceProvider)),
);

/// Analytics for the given filter set. autoDispose so leaving the screen frees
/// it; the family key re-fetches whenever the admin changes a filter.
final reportAnalyticsProvider = FutureProvider.autoDispose
    .family<ReportAnalytics, AnalyticsQuery>((ref, query) {
  return ref.watch(reportAnalyticsServiceProvider).fetch(query);
});
