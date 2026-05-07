import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/project_model.dart';

class ProjectAdminService {
  ProjectAdminService(this._api);

  final ApiService _api;

  Future<List<ProjectAdminModel>> listProjects({String? search}) async {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final response = await _api.get(
      ApiConstants.projects,
      queryParameters: query.isEmpty ? null : query,
    );
    return _api
        .extractList(response)
        .map((item) => ProjectAdminModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ProjectAdminModel> createProject(Map<String, dynamic> payload) async {
    final response = await _api.post(ApiConstants.projects, data: payload);
    return ProjectAdminModel.fromJson(_api.extractObject(response));
  }

  Future<ProjectAdminModel> updateProject(
      String id, Map<String, dynamic> payload) async {
    final response =
        await _api.patch('${ApiConstants.projects}/$id', data: payload);
    return ProjectAdminModel.fromJson(_api.extractObject(response));
  }

  Future<void> deactivateProject(String id) async {
    await _api.delete('${ApiConstants.projects}/$id');
  }
}
