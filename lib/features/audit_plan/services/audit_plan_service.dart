import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/audit_plan_model.dart';

class AuditPlanService {
  AuditPlanService(this._apiService);

  final ApiService _apiService;

  Future<List<AuditPlanModel>> getPlans() async {
    final response = await _apiService.get(ApiConstants.auditPlans);
    final list = _apiService.extractList(response);
    return list
        .map((item) => AuditPlanModel.fromJson(item as Map<String, dynamic>))
        .toList()
        .cast<AuditPlanModel>();
  }

  Future<List<ProjectLookupModel>> getProjects() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        '${ApiConstants.leadsBaseUrl}${ApiConstants.wonLeads}',
      );

      final list = _extractList(response.data);
      return list
          .map(
            (item) => ProjectLookupModel.fromJson(
              item as Map<String, dynamic>,
              isFromLeadsApi: true,
            ),
          )
          .toList();
    } catch (e) {
      // Fallback to regular projects API if leads API fails
      final response = await _apiService.get(ApiConstants.projects);
      final list = _apiService.extractList(response);
      return list
          .map(
            (item) => ProjectLookupModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
    }
    return <dynamic>[];
  }

  Future<List<UserLookupModel>> getAuditors() =>
      _fetchUserLookup(ApiConstants.auditors);

  Future<List<UserLookupModel>> getProjectIncharges() =>
      _fetchUserLookup(ApiConstants.projectIncharges);

  Future<List<UserLookupModel>> getClusterManagers() =>
      _fetchUserLookup(ApiConstants.clusterManagers);

  Future<List<UserLookupModel>> _fetchUserLookup(String path) async {
    final response = await _apiService.get(path);
    final list = _apiService.extractList(response);
    return list
        .map((item) => UserLookupModel.fromJson(item as Map<String, dynamic>))
        .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
        .toList();
  }

  Future<List<AuditPlanModel>> getReleasedAudits() async {
    final response = await _apiService.get(
      ApiConstants.releasedAudits,
      queryParameters: {'status': 'released'},
    );
    final list = _apiService.extractList(response);
    return list
        .map((item) => AuditPlanModel.fromJson(item as Map<String, dynamic>))
        .toList()
        .cast<AuditPlanModel>();
  }

  Future<AuditPlanModel> createPlan(Map<String, dynamic> data) async {
    final payload = {
      'project_id': data['project_id'] ?? data['projectId'],
      'auditor_id': data['auditor_id'] ?? data['auditorId'],
      'project_incharge_id':
          data['project_incharge_id'] ?? data['projectInchargeId'],
      'cluster_manager_id':
          data['cluster_manager_id'] ?? data['clusterManagerId'],
      'audit_date': data['audit_date'] ?? data['auditDate'],
      'location': data['location'],
      'remarks': data['remarks'],
      'status': data['status'] ?? 'draft',
    };
    final response = await _apiService.post(
      ApiConstants.auditPlans,
      data: payload,
    );
    return AuditPlanModel.fromJson(_apiService.extractObject(response));
  }

  Future<AuditPlanModel> releasePlan(Map<String, dynamic> data) async {
    final planId = data['id']?.toString() ?? '';
    if (planId.isEmpty) {
      // Create draft first, then release it using the ID in the body
      final draft = await createPlan({...data, 'status': 'draft'});
      final response = await _apiService.patch(
        ApiConstants.releaseAuditPlans,
        data: {'id': draft.id, 'audit_plan_id': draft.id},
      );
      return AuditPlanModel.fromJson(_apiService.extractObject(response));
    }
    // Release existing plan using the ID in the body
    final response = await _apiService.patch(
      ApiConstants.releaseAuditPlans,
      data: {'id': planId, 'audit_plan_id': planId},
    );
    return AuditPlanModel.fromJson(_apiService.extractObject(response));
  }

  Future<void> reschedulePlan({
    required String id,
    required DateTime newDate,
    required String reason,
  }) async {
    await _apiService.patch(
      ApiConstants.rescheduleAuditPlan(id),
      data: {
        'new_date': newDate.toIso8601String().split('T').first,
        'reason': reason,
      },
    );
  }

  /// Permanently hard-deletes a planned audit and every record that hangs off
  /// it — the audit sheet, parameters, parameter photos, action plan, action
  /// items, attachments and their S3 objects — in a single backend
  /// transaction. The backend rejects this (400) once the audit sheet is
  /// `submitted` or `acknowledged`, so an executed audit can't be purged.
  ///
  /// Returns the per-table row counts and S3 object counts that were removed.
  Future<AuditPlanDeletionResult> deletePlan(String id) async {
    final response =
        await _apiService.delete(ApiConstants.hardDeleteAuditPlan(id));
    return AuditPlanDeletionResult.fromJson(
      _apiService.extractObject(response),
    );
  }
}
