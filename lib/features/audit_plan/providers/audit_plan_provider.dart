import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/audit_plan_model.dart';
import '../services/audit_plan_service.dart';

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

  void _invalidateDashboards() {
    _ref.invalidate(adminDashboardProvider);
    _ref.invalidate(auditorDashboardProvider);
    _ref.invalidate(ownerDashboardProvider);
  }
}
