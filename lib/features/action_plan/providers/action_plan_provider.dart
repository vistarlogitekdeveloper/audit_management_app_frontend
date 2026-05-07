import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/action_plan_model.dart';
import '../services/action_plan_service.dart';

final actionPlanServiceProvider = Provider<ActionPlanService>(
  (ref) => ActionPlanService(ref.watch(apiServiceProvider)),
);

final actionPlanProvider = ChangeNotifierProvider<ActionPlanProvider>(
  (ref) => ActionPlanProvider(ref, ref.watch(actionPlanServiceProvider)),
);

class ActionPlanProvider extends ChangeNotifier {
  ActionPlanProvider(this._ref, this._service);

  final Ref _ref;
  final ActionPlanService _service;

  ActionPlanModel? currentPlan;
  List<ActionItemModel> items = [];
  bool isLoading = false;
  String? error;

  /// Loads an existing action plan (created by acknowledge). Caller can pass
  /// [fallbackItems] (built from the audit sheet's fail rows) to display
  /// before the backend has the plan persisted, but the plan itself must
  /// exist for the user to be able to save changes.
  Future<void> loadActionPlan(
    String auditSheetId, {
    List<ActionItemModel> fallbackItems = const [],
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final plan = await _service.getActionPlan(auditSheetId);
      currentPlan = plan;
      items = plan?.items.isNotEmpty == true ? plan!.items : fallbackItems;
    } catch (e) {
      error = e.toString();
      items = fallbackItems;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateItem(int index, ActionItemModel item) {
    items[index] = item;
    notifyListeners();
  }

  /// Validates that every item has a corrective action, responsible person,
  /// audit parameter id, and a due date within [planDeadline].
  /// Returns the indices that failed validation.
  List<int> validate({DateTime? planDeadline}) {
    final invalid = <int>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final missingText = item.correctiveAction.trim().isEmpty ||
          item.responsiblePerson.trim().isEmpty;
      final missingFk = item.auditParameterId.isEmpty;
      final overDeadline = planDeadline != null &&
          item.dueDate.isAfter(planDeadline.add(const Duration(days: 1)));
      if (missingText || missingFk || overDeadline) invalid.add(i);
    }
    return invalid;
  }

  Future<void> save() async {
    final plan = currentPlan;
    if (plan == null || plan.id.isEmpty) {
      throw StateError(
        'No action plan to save. Acknowledge the audit first to create one.',
      );
    }
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      currentPlan = await _service.updateActionPlan(
        planId: plan.id,
        items: items,
      );
      items = currentPlan!.items.isNotEmpty ? currentPlan!.items : items;
      _ref.invalidate(ownerDashboardProvider);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
