import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/audit_parameter_model.dart';
import '../models/audit_sheet_model.dart';

class AcknowledgeResult {
  const AcknowledgeResult({required this.hasFailPoints, this.actionPlanId});
  final bool hasFailPoints;
  final String? actionPlanId;
}

class AuditSheetService {
  AuditSheetService(this._apiService);

  final ApiService _apiService;

  /// Returns the audit sheet for [auditId] (an audit-plan id), or `null` when
  /// the backend has no sheet for it yet (404) — a not-yet-started audit,
  /// which the caller should treat as "show a fresh blank sheet", not an
  /// error. Other failures (network/5xx) still throw.
  Future<AuditSheetModel?> getSheet(String auditId) async {
    try {
      final response = await _apiService.get(ApiConstants.auditSheet(auditId));
      return AuditSheetModel.fromJson(_apiService.extractObject(response));
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  Future<AuditSheetModel> updateSheet({
    required String auditId,
    required List<Map<String, dynamic>> data,
    String status = AppConstants.statusDraft,
  }) async {
    final response = await _apiService.patch(
      ApiConstants.auditSheet(auditId),
      data: {
        'parameters': data
            .map(
              (row) => {
                'param_index': row['index'],
                'result': row['result'],
                'remark': row['remark'],
              },
            )
            .toList(),
        'status': status,
      },
    );
    return AuditSheetModel.fromJson(_apiService.extractObject(response));
  }

  Future<void> submitSheet(String auditId) async {
    await _apiService.post(ApiConstants.submitAuditSheet(auditId));
  }

  /// Uploads a photo for one parameter (one image per parameter; re-uploading
  /// overwrites it server-side). [auditId] is the audit-plan id. Returns a
  /// browser-loadable (http) URL when the backend provides one (presigned),
  /// otherwise `null` — the upload still succeeded, but the raw `s3://` URI
  /// can't be rendered, so the caller keeps the local preview for now.
  Future<String?> uploadParameterImage({
    required String auditId,
    required int paramIndex,
    required String filePath,
  }) async {
    final formData = FormData.fromMap({
      'param_index': paramIndex,
      'image': await MultipartFile.fromFile(filePath),
    });
    final response = await _apiService.upload(
      ApiConstants.uploadAuditSheetImage(auditId),
      formData: formData,
    );
    final data = _apiService.extractObject(response);
    for (final key in const [
      'presigned_url',
      'signed_url',
      'url',
      'image_url',
    ]) {
      final value = data[key]?.toString();
      if (value != null && value.startsWith('http')) return value;
    }
    return null;
  }

  Future<AcknowledgeResult> acknowledgeSheet(
    String auditId,
    String ownerRemarks,
  ) async {
    final response = await _apiService.post(
      ApiConstants.acknowledgeAuditSheet(auditId),
      data: {'owner_remarks': ownerRemarks},
    );
    final data = _apiService.extractObject(response);
    return AcknowledgeResult(
      hasFailPoints: data['hasFailPoints'] == true,
      actionPlanId: data['actionPlanId']?.toString(),
    );
  }

  // Result returned by /api/audit-sheets/:id/acknowledge.
  AuditSheetModel emptyTemplate({
    required String auditId,
    required String projectName,
    required String auditorName,
    required String location,
  }) {
    return AuditSheetModel(
      id: auditId,
      auditPlanId: auditId,
      projectName: projectName,
      auditorName: auditorName,
      location: location,
      auditDate: DateTime.now(),
      parameters: List.generate(
        AppConstants.auditParameters.length,
        (index) => AuditParameterModel(
          index: index + 1,
          name: AppConstants.auditParameters[index],
        ),
      ),
    );
  }
}
