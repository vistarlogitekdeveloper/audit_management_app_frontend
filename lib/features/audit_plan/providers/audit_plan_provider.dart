import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/audit_plan_model.dart';
import '../services/audit_plan_service.dart';

const Set<String> _deletableAuditPlanStatuses = {
  AppConstants.statusDraft,
  AppConstants.statusReleased,
};

/// Whether an audit plan in [status] may be deleted from the UI.
///
/// The hard-delete endpoint gates on the audit SHEET status (it refuses, 400,
/// once the sheet is `submitted` or `acknowledged`). The plan / upcoming lists
/// don't expose the sheet status, so we use the plan status as a close proxy:
/// draft and released plans normally have a not-started or draft sheet, which
/// the backend allows deleting. The backend 400 remains the real guard.
bool isAuditPlanDeletable(String status) =>
    _deletableAuditPlanStatuses.contains(status.trim().toLowerCase());

final auditPlanServiceProvider = Provider<AuditPlanService>(
  (ref) => AuditPlanService(ref.watch(apiServiceProvider)),
);

final auditPlanProvider = ChangeNotifierProvider<AuditPlanProvider>(
  (ref) => AuditPlanProvider(ref, ref.watch(auditPlanServiceProvider)),
);

class AuditPlanProvider extends ChangeNotifier {
  AuditPlanProvider(this._ref, this._service);

  final Ref _ref;
  final AuditPlanService _service;

  List<AuditPlanModel> plans = [];
  List<ProjectLookupModel> projects = [];
  List<UserLookupModel> auditors = [];
  List<UserLookupModel> projectIncharges = [];
  List<UserLookupModel> clusterManagers = [];
  List<AuditPlanModel> releasedAudits = [];
  bool isLoading = false;
  bool lookupsLoading = false;
  String? lookupsError;

  /// Set when [bootstrap] failed to load one of its data sets, so screens can
  /// show an error instead of silently empty filters/lists. (Distinct from
  /// [lookupsError], which only covers the user-lookup dropdowns.)
  String? bootstrapError;

  Future<void> bootstrap() async {
    bootstrapError = null;
    try {
      await Future.wait([
        fetchPlans(),
        fetchProjects(),
        fetchUserLookups(),
        fetchReleasedAudits(),
      ]);
    } catch (e) {
      // Without this catch the rejection escapes the unawaited microtask in
      // initState as an unhandled async error and the user sees nothing.
      bootstrapError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> fetchPlans() async {
    isLoading = true;
    notifyListeners();
    try {
      plans = await _service.getPlans();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProjects() async {
    projects = await _service.getProjects();
    notifyListeners();
  }

  Future<void> fetchUserLookups() async {
    lookupsLoading = true;
    lookupsError = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getProjectIncharges(),
        _service.getClusterManagers(),
        _service.getAuditors(),
      ]);
      projectIncharges = results[0];
      clusterManagers = results[1];
      auditors = results[2];
    } catch (e) {
      lookupsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      lookupsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAuditors() async {
    auditors = await _service.getAuditors();
    notifyListeners();
  }

  Future<void> fetchProjectIncharges() async {
    projectIncharges = await _service.getProjectIncharges();
    notifyListeners();
  }

  Future<void> fetchClusterManagers() async {
    clusterManagers = await _service.getClusterManagers();
    notifyListeners();
  }

  Future<void> fetchReleasedAudits() async {
    releasedAudits = await _service.getReleasedAudits();
    notifyListeners();
  }

  Future<AuditPlanModel> createPlan(Map<String, dynamic> data) async {
    isLoading = true;
    notifyListeners();
    try {
      final plan =
          data['status'] == 'released'
              ? await _service.releasePlan(data)
              : await _service.createPlan(data);
      plans = [plan, ...plans];

      // Invalidate dashboard data to reflect changes
      _invalidateDashboards();

      return plan;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Updates a draft plan's editable fields in place. Refreshes the cached
  /// `plans` list so the calendar / reports UI reflects the change without
  /// another round trip.
  Future<AuditPlanModel> updatePlan(
    String id,
    Map<String, dynamic> data,
  ) async {
    isLoading = true;
    notifyListeners();
    try {
      final updated = await _service.updatePlan(id, data);
      plans = [
        for (final p in plans)
          if (p.id == updated.id) updated else p,
      ];
      _invalidateDashboards();
      return updated;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Releases a saved draft (no field changes). Moves the plan from `draft`
  /// to `released` and re-fetches the released list so downstream screens
  /// see it appear.
  Future<AuditPlanModel> releaseDraftPlan(String id) async {
    isLoading = true;
    notifyListeners();
    try {
      final released = await _service.releaseExistingPlan(id);
      plans = [
        for (final p in plans)
          if (p.id == released.id) released else p,
      ];
      await fetchReleasedAudits();
      _invalidateDashboards();
      return released;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reschedulePlan({
    required String id,
    required DateTime newDate,
    required String reason,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.reschedulePlan(id: id, newDate: newDate, reason: reason);
      await fetchReleasedAudits();

      // Invalidate dashboard data to reflect changes
      _invalidateDashboards();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Hard-deletes a planned audit by [id] and returns the cascade delete
  /// counts.
  ///
  /// Optimistically removes the entry from [plans] before the API call so the
  /// UI reacts immediately.  On failure the plan is restored and the error is
  /// rethrown so the caller can surface it to the user.
  Future<AuditPlanDeletionResult> deletePlan(String id) async {
    // Snapshot the current list so we can roll back on error.
    final previousPlans = List<AuditPlanModel>.from(plans);
    plans = plans.where((p) => p.id != id).toList();
    notifyListeners();

    try {
      final result = await _service.deletePlan(id);
      _invalidateDashboards();
      return result;
    } catch (_) {
      // Roll back to the previous state.
      plans = previousPlans;
      notifyListeners();
      rethrow;
    }
  }

  void _invalidateDashboards() {
    _ref.invalidate(adminDashboardProvider);
    _ref.invalidate(auditorDashboardProvider);
    _ref.invalidate(ownerDashboardProvider);
  }
}
