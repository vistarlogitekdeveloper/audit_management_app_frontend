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

  /// Photos staged by the owner but not yet uploaded. Keyed by item index.
  /// Picking only adds to this map + the visible thumbnail list; the actual
  /// multipart POST is deferred until [save] / submit flushes the queue.
  /// Same pattern the audit sheet uses — keeps the picker fast and lets the
  /// owner remove freely without per-tap API traffic.
  final Map<int, List<_PendingActionPhoto>> _pendingPhotos = {};

  /// Native staging: file path on disk. Used on Android / iOS / desktop
  /// where `dart:io` File can read the picker's path directly.
  void stagePhotoFromPath(int index, String filePath) {
    if (index < 0 || index >= items.length) return;
    _appendDisplayed(index, filePath);
    (_pendingPhotos[index] ??= []).add(_PendingActionPhoto(
      previewPath: filePath,
      filePath: filePath,
    ));
    notifyListeners();
  }

  /// Web staging: in-memory bytes + filename. [previewPath] is the picker's
  /// `blob:` URL the thumbnail renders from until the flush swaps in the
  /// server URL.
  void stagePhotoFromBytes({
    required int index,
    required String previewPath,
    required Uint8List bytes,
    required String filename,
  }) {
    if (index < 0 || index >= items.length) return;
    _appendDisplayed(index, previewPath);
    (_pendingPhotos[index] ??= []).add(_PendingActionPhoto(
      previewPath: previewPath,
      bytes: bytes,
      filename: filename,
    ));
    notifyListeners();
  }

  void _appendDisplayed(int index, String pathOrPreview) {
    final current = items[index];
    items[index] = current.copyWith(
      imagePaths: [...current.imagePaths, pathOrPreview],
    );
  }

  /// Removes the photo at [photoIndex] for the item at [index]. Mirrors the
  /// × badge on the audit-sheet row — also drops the entry from the pending
  /// upload queue so a removed-before-flush photo never reaches the backend.
  void removeItemImageAt(int index, int photoIndex) {
    if (index < 0 || index >= items.length) return;
    final current = items[index];
    if (photoIndex < 0 || photoIndex >= current.imagePaths.length) return;
    final removedPath = current.imagePaths[photoIndex];
    final next = [...current.imagePaths]..removeAt(photoIndex);
    items[index] = current.copyWith(imagePaths: next);
    _pendingPhotos[index]?.removeWhere((p) => p.previewPath == removedPath);
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
      // Flush staged photos first so the upcoming PATCH `images` array
      // contains every uploaded URL. If a single upload fails the whole
      // save aborts — the owner gets a clear error rather than discovering
      // half their evidence got through.
      await _flushPendingPhotosLocked(plan.id);
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

  /// Uploads every staged photo via the per-item endpoint, swapping each
  /// preview entry to its returned server URL in place. Throws on the first
  /// failure so the surrounding save() rejects with a useful message instead
  /// of partial state. Caller already holds the [isLoading] lock.
  Future<void> _flushPendingPhotosLocked(String planId) async {
    for (final index in _pendingPhotos.keys.toList()) {
      final list = _pendingPhotos[index]!;
      while (list.isNotEmpty) {
        // Item must exist server-side before we can attach a photo — new
        // (un-id'd) items skip the upload but stay queued so a follow-up
        // save catches them once the first save has persisted their ids.
        if (index < 0 || index >= items.length) {
          list.clear();
          break;
        }
        final itemId = items[index].id;
        if (itemId == null || itemId.isEmpty) {
          // Defer — leave the photo staged for the next save() after this
          // one persists the item and returns its id.
          break;
        }
        final photo = list.first;
        String? url;
        if (photo.bytes != null) {
          url = await _service.uploadActionItemImageBytes(
            planId: planId,
            itemId: itemId,
            bytes: photo.bytes!,
            filename: photo.filename ?? 'photo.jpg',
          );
        } else if (photo.filePath != null) {
          url = await _service.uploadActionItemImage(
            planId: planId,
            itemId: itemId,
            filePath: photo.filePath!,
          );
        }
        if (url != null) _swapPreview(index, photo.previewPath, url);
        list.removeAt(0);
      }
    }
  }

  void _swapPreview(int index, String previewPath, String serverUrl) {
    if (index < 0 || index >= items.length) return;
    final current = items[index];
    final pos = current.imagePaths.indexOf(previewPath);
    if (pos < 0) return;
    final next = [...current.imagePaths];
    next[pos] = serverUrl;
    items[index] = current.copyWith(imagePaths: next);
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

/// One photo staged on an action item, waiting for the next [save] to flush
/// it to the per-item upload endpoint. Either [filePath] (native) or
/// [bytes] + [filename] (web) is populated. [previewPath] is the entry the
/// thumbnail renders from — the flush swaps it to the server URL on success.
class _PendingActionPhoto {
  const _PendingActionPhoto({
    required this.previewPath,
    this.filePath,
    this.bytes,
    this.filename,
  });

  final String previewPath;
  final String? filePath;
  final Uint8List? bytes;
  final String? filename;
}
