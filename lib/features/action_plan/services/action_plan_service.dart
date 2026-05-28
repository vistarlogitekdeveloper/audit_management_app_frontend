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
    } on ApiException catch (e) {
      // 404 == no plan exists for this sheet yet → null. Let real failures
      // (network/5xx) propagate so the provider can surface them instead of
      // masking everything as "no plan".
      if (e.isNotFound) return null;
      rethrow;
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

  /// Auditor verdict on a single item. [reviewStatus] is 'approved' or
  /// 'rejected'; [remark] is required when rejecting. Returns the updated
  /// item only (same shape as items in GET /action-plans/:auditSheetId).
  Future<ActionItemModel> reviewItem({
    required String planId,
    required String itemId,
    required String reviewStatus,
    String? remark,
  }) async {
    final response = await _apiService.patch(
      ApiConstants.actionPlanItemReview(planId, itemId),
      data: {
        'review_status': reviewStatus,
        if (remark != null && remark.trim().isNotEmpty) 'remark': remark.trim(),
      },
    );
    return ActionItemModel.fromJson(_apiService.extractObject(response));
  }

  /// Auditor closes the plan. Backend 409s if any item is not approved.
  Future<ActionPlanModel> closePlan({
    required String planId,
    String? remark,
  }) async {
    final response = await _apiService.post(
      ApiConstants.actionPlanClose(planId),
      data: {
        if (remark != null && remark.trim().isNotEmpty) 'remark': remark.trim(),
      },
    );
    return ActionPlanModel.fromJson(_apiService.extractObject(response));
  }
}
