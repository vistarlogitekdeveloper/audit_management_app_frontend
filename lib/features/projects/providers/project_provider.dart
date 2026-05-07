import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../../audit_plan/providers/audit_plan_provider.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';

final projectAdminServiceProvider = Provider<ProjectAdminService>(
  (ref) => ProjectAdminService(ref.watch(apiServiceProvider)),
);

final projectAdminProvider = ChangeNotifierProvider<ProjectAdminProvider>(
  (ref) => ProjectAdminProvider(ref, ref.watch(projectAdminServiceProvider)),
);

class ProjectAdminProvider extends ChangeNotifier {
  ProjectAdminProvider(this._ref, this._service);

  final Ref _ref;
  final ProjectAdminService _service;

  List<ProjectAdminModel> projects = [];
  bool isLoading = false;
  String? error;
  String search = '';

  Future<void> fetchProjects() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      projects = await _service.listProjects();
      // Make sure incharge/cluster lookups are warm for the form
      final auditPlan = _ref.read(auditPlanProvider);
      if (auditPlan.projectIncharges.isEmpty) {
        await auditPlan.fetchProjectIncharges();
      }
      if (auditPlan.clusterManagers.isEmpty) {
        await auditPlan.fetchClusterManagers();
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    search = value;
    notifyListeners();
  }

  List<ProjectAdminModel> get filtered {
    final query = search.trim().toLowerCase();
    if (query.isEmpty) return projects;
    return projects
        .where((project) =>
            project.name.toLowerCase().contains(query) ||
            project.location.toLowerCase().contains(query) ||
            project.clientName.toLowerCase().contains(query))
        .toList();
  }

  Future<void> createProject(Map<String, dynamic> payload) async {
    final created = await _service.createProject(payload);
    projects = [created, ...projects];
    notifyListeners();
  }

  Future<void> updateProject(String id, Map<String, dynamic> payload) async {
    final updated = await _service.updateProject(id, payload);
    projects = projects.map((p) => p.id == id ? updated : p).toList();
    notifyListeners();
  }

  Future<void> deactivateProject(String id) async {
    await _service.deactivateProject(id);
    projects = projects
        .map((p) => p.id == id ? p.copyWith(isActive: false) : p)
        .toList();
    notifyListeners();
  }
}
