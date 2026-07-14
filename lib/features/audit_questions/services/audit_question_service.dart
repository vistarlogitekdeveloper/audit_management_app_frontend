import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/audit_question_model.dart';

class AuditQuestionService {
  AuditQuestionService(this._api);

  final ApiService _api;

  /// Lists the master audit questions. [includeInactive] is honoured only for
  /// admins server-side; other roles always get the active list (used to build
  /// blank sheets, render descriptions and order the action plan).
  Future<List<AuditQuestionModel>> listQuestions({
    bool includeInactive = false,
  }) async {
    final response = await _api.get(
      ApiConstants.auditQuestions,
      queryParameters:
          includeInactive ? {'includeInactive': 'true'} : null,
    );
    return _api
        .extractList(response)
        .map((item) =>
            AuditQuestionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AuditQuestionModel> createQuestion({
    required String name,
    String? description,
  }) async {
    final response = await _api.post(
      ApiConstants.auditQuestions,
      data: {'name': name, 'description': description ?? ''},
    );
    return AuditQuestionModel.fromJson(_api.extractObject(response));
  }

  Future<AuditQuestionModel> updateQuestion(
    String id, {
    String? name,
    String? description,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (description != null) payload['description'] = description;
    if (isActive != null) payload['is_active'] = isActive;
    final response = await _api.patch(
      ApiConstants.auditQuestionById(id),
      data: payload,
    );
    return AuditQuestionModel.fromJson(_api.extractObject(response));
  }

  /// Soft-deletes (deactivates) a question. Historical audits are unaffected —
  /// they snapshot the question name on their own parameter rows.
  Future<void> deleteQuestion(String id) async {
    await _api.delete(ApiConstants.auditQuestionById(id));
  }

  /// Persists a new display order. [orderedIds] is the full list of question
  /// ids top-to-bottom; the server writes each one's position as sort_order.
  Future<List<AuditQuestionModel>> reorder(List<String> orderedIds) async {
    final response = await _api.patch(
      ApiConstants.reorderAuditQuestions,
      data: {'order': orderedIds},
    );
    return _api
        .extractList(response)
        .map((item) =>
            AuditQuestionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
