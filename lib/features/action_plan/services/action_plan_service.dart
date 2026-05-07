import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/action_plan_model.dart';

class ActionPlanService {
  ActionPlanService(this._apiService);

  final ApiService _apiService;

  /// Fetch the action plan auto-created by /audit-sheets/:id/acknowledge.
  /// Returns null if the plan does not exist yet.
  Future<ActionPlanModel?> getActionPlan(String auditSheetId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.actionPlanByAuditSheet(auditSheetId),
      );
      if (response == null) return null;
      return ActionPlanModel.fromJson(_apiService.extractObject(response));
    } catch (_) {
      // Backend returns 404 when no plan exists for the sheet — treat as null.
      return null;
    }
  }

  /// Save items into an existing plan. Use the plan id (NOT the audit-sheet id).
  /// Backend validation requires every item to carry a real audit_parameter_id.
  Future<ActionPlanModel> updateActionPlan({
    required String planId,
    required List<ActionItemModel> items,
  }) async {
    final response = await _apiService.patch(
      ApiConstants.actionPlanById(planId),
      data: {
        'items': items
            .map(
              (item) => {
                'audit_parameter_id': item.auditParameterId,
                'fail_point': item.parameterName,
                'corrective_action': item.correctiveAction,
                'responsible_person': item.responsiblePerson,
                'due_date': item.dueDate.toIso8601String().split('T').first,
                'status': item.statusForApi,
              },
            )
            .toList(),
      },
    );
    return ActionPlanModel.fromJson(_apiService.extractObject(response));
  }
}
