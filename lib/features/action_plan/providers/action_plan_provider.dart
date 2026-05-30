import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../../action_plan_tracker/providers/action_plan_tracker_provider.dart';
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

  /// True while the auditor's per-item review or plan-close call is in flight.
  /// Distinct from [isLoading] so the page-level overlay doesn't fire on
  /// every Approve/Reject tap.
  bool isReviewing = false;

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
    // A stale ActionItemWidget callback can fire with an old index while a
    // save() has just swapped in a shorter items list — guard the range.
    if (index < 0 || index >= items.length) return;
    items[index] = item;
    notifyListeners();
  }

  /// Appends [imagePath] to the item's image list — local-only for now.
  /// The backend has no action-item image endpoint yet, so saving an
  /// item doesn't upload these. They stay for the session so the owner
  /// can review what they staged before submitting. When the backend
  /// endpoint ships, [save] will flush the unsynced paths in one pass
  /// (same pattern audit sheets already use).
  void stageItemImage(int index, String imagePath) {
    if (index < 0 || index >= items.length) return;
    final current = items[index];
    items[index] = current.copyWith(
      imagePaths: [...current.imagePaths, imagePath],
    );
    notifyListeners();
  }

  /// Removes the photo at [photoIndex] for the item at [index]. Mirrors
  /// the × badge tap on the audit-sheet row.
  void removeItemImageAt(int index, int photoIndex) {
    if (index < 0 || index >= items.length) return;
    final current = items[index];
    if (photoIndex < 0 || photoIndex >= current.imagePaths.length) return;
    final next = [...current.imagePaths]..removeAt(photoIndex);
    items[index] = current.copyWith(imagePaths: next);
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

  /// Auditor approves / rejects a single item. Backend returns the updated
  /// item; we swap it back into [items] by id so the UI updates without a
  /// full reload.
  Future<void> reviewItem({
    required String itemId,
    required String reviewStatus,
    String? remark,
  }) async {
    final plan = currentPlan;
    if (plan == null || plan.id.isEmpty) {
      throw StateError('No action plan loaded.');
    }
    isReviewing = true;
    error = null;
    notifyListeners();
    try {
      final updated = await _service.reviewItem(
        planId: plan.id,
        itemId: itemId,
        reviewStatus: reviewStatus,
        remark: remark,
      );
      final idx = items.indexWhere((i) => i.id == itemId);
      if (idx >= 0) items[idx] = updated;
      // Per-plan totals on the tracker depend on per-item review state;
      // invalidate so the auditor's list pills refresh next time it opens.
      _ref.read(actionPlanTrackerProvider).fetch();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isReviewing = false;
      notifyListeners();
    }
  }

  /// Auditor closes the plan. Backend 409s if any item is not approved —
  /// the caller surfaces the message; we just propagate the error.
  Future<void> closePlan({String? remark}) async {
    final plan = currentPlan;
    if (plan == null || plan.id.isEmpty) {
      throw StateError('No action plan loaded.');
    }
    isReviewing = true;
    error = null;
    notifyListeners();
    try {
      currentPlan = await _service.closePlan(planId: plan.id, remark: remark);
      items = currentPlan!.items.isNotEmpty ? currentPlan!.items : items;
      _ref.read(actionPlanTrackerProvider).fetch();
      _ref.invalidate(ownerDashboardProvider);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isReviewing = false;
      notifyListeners();
    }
  }
}
