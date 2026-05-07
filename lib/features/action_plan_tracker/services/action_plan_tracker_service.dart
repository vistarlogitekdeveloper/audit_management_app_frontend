import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/action_plan_summary.dart';

class ActionPlanTrackerService {
  ActionPlanTrackerService(this._api);

  final ApiService _api;

  Future<List<ActionPlanSummary>> list({String? status}) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status != 'all') {
      query['status'] = status;
    }
    final response = await _api.get(
      ApiConstants.actionPlansList,
      queryParameters: query.isEmpty ? null : query,
    );
    return _api
        .extractList(response)
        .map((item) => ActionPlanSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
