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
    // Drop rows the auditor hasn't answered yet (result == null). Draft saves
    // happen constantly while the sheet is still half-filled, and the backend
    // Joi schema rejects the whole PATCH if any row's `result` isn't one of
    // [pass, fail, na] — sending null 400s the request and loses the draft.
    final parameters = <Map<String, dynamic>>[];
    for (final row in data) {
      final result = row['result'];
      if (result == null) continue;
      final resultText = result.toString();
      if (resultText.isEmpty) continue;
      parameters.add({
        'param_index': row['index'],
        'result': resultText,
        'remark': row['remark'],
      });
    }
    final response = await _apiService.patch(
      ApiConstants.auditSheet(auditId),
      data: {
        'parameters': parameters,
        'status': status,
      },
    );
    return AuditSheetModel.fromJson(_apiService.extractObject(response));
  }

  Future<void> submitSheet(String auditId) async {
    await _apiService.post(ApiConstants.submitAuditSheet(auditId));
  }

  /// Uploads one photo against [paramIndex] on the sheet. Caller passes
  /// either [filePath] (mobile, image_picker's `XFile.path`) or [bytes]
  /// (web, `XFile.readAsBytes()` — paths are synthetic blobs there).
  /// Returns the presigned HTTPS URL the backend stored, which the caller
  /// drops straight into the row's [AuditRowState.imageUrls] for display.
  ///
  /// Tolerates three response shapes — the current backend returns the
  /// presigned URL on `presigned_url` / `url` (with `image_url` carrying
  /// the `s3://` canonical), and a pending swap will move the presigned
  /// URL onto `image_url` itself. We pick whichever HTTP(S) value lands
  /// first so the rollout doesn't break the row strip.
  Future<String> uploadParameterImage({
    required String auditId,
    required int paramIndex,
    required List<int> bytes,
    String? filename,
    String? mimeType,
  }) async {
    final response = await _apiService.postMultipart(
      ApiConstants.uploadAuditSheetImage(auditId),
      fileField: 'image',
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
      fields: {'param_index': paramIndex.toString()},
    );
    final data = _apiService.extractObject(response);
    for (final key in const ['presigned_url', 'url', 'image_url']) {
      final value = data[key];
      if (value is String &&
          (value.startsWith('http') || value.startsWith('data:'))) {
        return value;
      }
    }
    throw const ApiException(
      message: 'Upload succeeded but the server did not return a URL.',
    );
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
