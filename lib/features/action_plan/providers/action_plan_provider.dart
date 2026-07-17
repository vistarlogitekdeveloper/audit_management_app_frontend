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

  /// Ids of action items with an attachment upload in flight, so each point's
  /// "Add" control can show a spinner without blocking the rest of the form.
  final Set<String> _uploadingItemIds = {};

  bool isUploadingAttachment(String? itemId) =>
      itemId != null && _uploadingItemIds.contains(itemId);

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

  /// Uploads an optional evidence file for one action-plan point and, on
  /// success, appends it to that item's attachment strip. [itemId] must be a
  /// persisted item id (the caller only offers the control once it is).
  Future<void> uploadAttachment({
    required String itemId,
    required List<int> bytes,
    String? filename,
    String? mimeType,
  }) async {
    final plan = currentPlan;
    if (plan == null || plan.id.isEmpty) {
      throw StateError('No action plan loaded.');
    }
    _uploadingItemIds.add(itemId);
    notifyListeners();
    try {
      final attachment = await _service.uploadItemAttachment(
        planId: plan.id,
        itemId: itemId,
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
      );
      final idx = items.indexWhere((i) => i.id == itemId);
      if (idx >= 0) {
        items[idx] = items[idx].copyWith(
          attachments: [...items[idx].attachments, attachment],
        );
      }
    } finally {
      _uploadingItemIds.remove(itemId);
      notifyListeners();
    }
  }

  /// Removes a previously-uploaded attachment from a point and the strip.
  Future<void> removeAttachment({
    required String itemId,
    required String attachmentId,
  }) async {
    final plan = currentPlan;
    if (plan == null || plan.id.isEmpty) {
      throw StateError('No action plan loaded.');
    }
    await _service.deleteItemAttachment(
      planId: plan.id,
      itemId: itemId,
      attachmentId: attachmentId,
    );
    final idx = items.indexWhere((i) => i.id == itemId);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(
        attachments: items[idx]
            .attachments
            .where((a) => a.id != attachmentId)
            .toList(),
      );
      notifyListeners();
    }
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
      final updated = await _service.updateActionPlan(
        planId: plan.id,
        items: items,
      );
      currentPlan = updated;
      // The update response doesn't echo owner attachments (they're managed
      // via their own endpoints and live in a separate table). Carry them
      // over by audit_parameter_id so the strip doesn't blank out after a
      // draft save — they remain persisted in the DB regardless.
      final attByParam = {
        for (final it in items) it.auditParameterId: it.attachments,
      };
      final incoming = updated.items.isNotEmpty ? updated.items : items;
      items = incoming.map((it) {
        final prior = attByParam[it.auditParameterId];
        if (prior != null && prior.isNotEmpty && it.attachments.isEmpty) {
          return it.copyWith(attachments: prior);
        }
        return it;
      }).toList();
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
