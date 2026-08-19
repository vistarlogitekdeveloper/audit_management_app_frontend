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
      return releaseExistingPlan(draft.id);
    }
    return releaseExistingPlan(planId);
  }

  /// Flips an existing draft to `released`. Backend refuses with 400 if the
  /// plan is already released/cancelled.
  Future<AuditPlanModel> releaseExistingPlan(String id) async {
    final response = await _apiService.patch(
      ApiConstants.releaseAuditPlans,
      data: {'id': id, 'audit_plan_id': id},
    );
    return AuditPlanModel.fromJson(_apiService.extractObject(response));
  }

  /// Edits a draft audit plan. Only the fields present in [data] are
  /// forwarded; the backend rejects the request once the plan is no longer
  /// in `draft` state.
  Future<AuditPlanModel> updatePlan(String id, Map<String, dynamic> data) async {
    // Keys pulled from either the snake_case or camelCase variant the FE
    // form may hand us. Values are sent as-is (including nulls) so that
    // clearing a field on the edit form actually nulls the DB column — an
    // empty-string cleanup step at the end drops accidental blanks.
    dynamic pick(String snake, String camel) {
      if (data.containsKey(snake)) return data[snake];
      if (data.containsKey(camel)) return data[camel];
      return _absent;
    }
    final raw = <String, dynamic>{
      'project_id': pick('project_id', 'projectId'),
      'auditor_id': pick('auditor_id', 'auditorId'),
      'project_incharge_id': pick('project_incharge_id', 'projectInchargeId'),
      'cluster_manager_id': pick('cluster_manager_id', 'clusterManagerId'),
      'audit_date': pick('audit_date', 'auditDate'),
      'location': data.containsKey('location') ? data['location'] : _absent,
      'remarks': data.containsKey('remarks') ? data['remarks'] : _absent,
    };
    final payload = <String, dynamic>{};
    raw.forEach((key, value) {
      if (identical(value, _absent)) return;
      // The empty-string variants come from cleared dropdowns/inputs; the
      // backend prefers explicit nulls (its Joi .empty('') maps '' → null
      // anyway, but sending null is unambiguous).
      if (value is String && value.isEmpty) {
        payload[key] = null;
      } else {
        payload[key] = value;
      }
    });

    final response = await _apiService.patch(
      ApiConstants.auditPlanById(id),
      data: payload,
    );
    return AuditPlanModel.fromJson(_apiService.extractObject(response));
  }

  static const Object _absent = Object();

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
