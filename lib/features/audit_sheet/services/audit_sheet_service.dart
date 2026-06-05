import 'dart:typed_data';

import 'package:http_parser/http_parser.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/audit_parameter_model.dart';
import '../models/audit_sheet_model.dart';

/// Picks a `MediaType` for an evidence upload based on the filename
/// extension. Defaults to `image/jpeg` because (a) it's what the picker
/// hands back in the vast majority of cases and (b) it's what the backend
/// expects when the filename is missing entirely. multer's fileFilter
/// rejects parts with no Content-Type, surfacing as "Image is required".
MediaType _imageMediaTypeFor(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return MediaType('image', 'png');
  if (lower.endsWith('.gif')) return MediaType('image', 'gif');
  if (lower.endsWith('.webp')) return MediaType('image', 'webp');
  if (lower.endsWith('.heic')) return MediaType('image', 'heic');
  if (lower.endsWith('.heif')) return MediaType('image', 'heif');
  return MediaType('image', 'jpeg');
}

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

  /// Uploads a photo for one parameter (one image per parameter; re-uploading
  /// overwrites it server-side). [auditId] is the audit-plan id. Returns a
  /// browser-loadable (http) URL when the backend provides one (presigned),
  /// otherwise `null` — the upload still succeeded, but the raw `s3://` URI
  /// can't be rendered, so the caller keeps the local preview for now.
  ///
  /// Routed through `ApiService.uploadMultipart` (package:http) rather than
  /// dio: dio's BrowserHttpClientAdapter mangles the multipart body on
  /// Flutter web and the backend responds "Image is required" even though
  /// the bytes are on the wire. The http path uses the browser's native
  /// FormData wiring on web and works the same on native.
  Future<String?> uploadParameterImage({
    required String auditId,
    required int paramIndex,
    required String filePath,
  }) async {
    final basename =
        filePath.split(RegExp(r'[\\/]')).last.split('?').first;
    final filename = basename.isEmpty ? 'photo.jpg' : basename;
    final response = await _apiService.uploadMultipart(
      ApiConstants.uploadAuditSheetImage(auditId),
      fileFieldName: 'image',
      filePath: filePath,
      filename: filename,
      contentType: _imageMediaTypeFor(filename),
      extraFields: {'param_index': paramIndex.toString()},
    );
    return _presignedUrlFrom(response);
  }

  /// Bytes variant of [uploadParameterImage] for Flutter web, where
  /// `dart:io` File and `path_provider` aren't available so a file-path
  /// upload can't be used. Otherwise identical — same endpoint, same
  /// response handling.
  Future<String?> uploadParameterImageBytes({
    required String auditId,
    required int paramIndex,
    required Uint8List bytes,
    required String filename,
  }) async {
    // Some web pickers hand back `XFile.name = ""` (camera captures, certain
    // browsers). multer treats a part with an empty filename as a plain
    // field and the backend responds "Image is required" — fall back to a
    // sensible name + explicit image Content-Type so the part is recognised.
    final safeName = filename.isEmpty ? 'photo.jpg' : filename;
    final response = await _apiService.uploadMultipart(
      ApiConstants.uploadAuditSheetImage(auditId),
      fileFieldName: 'image',
      bytes: bytes,
      filename: safeName,
      contentType: _imageMediaTypeFor(safeName),
      extraFields: {'param_index': paramIndex.toString()},
    );
    return _presignedUrlFrom(response);
  }

  /// Pulls the first browser-loadable (http) URL out of an upload response.
  /// Returns null when only an internal `s3://` URI is present — the upload
  /// still succeeded; the caller keeps the local preview for now.
  String? _presignedUrlFrom(Map<String, dynamic> response) {
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
