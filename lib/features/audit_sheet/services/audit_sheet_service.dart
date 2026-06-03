import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/audit_parameter_model.dart';
import '../models/audit_sheet_model.dart';

/// Picks a `DioMediaType` (aliased `MediaType` from http_parser) for an
/// evidence upload based on the filename extension. Defaults to
/// `image/jpeg` because (a) it's what the picker hands back in the vast
/// majority of cases and (b) it's what the backend expects when the
/// filename is missing entirely. multer's fileFilter rejects parts with no
/// Content-Type, which surfaces as "Image is required" on the server side.
DioMediaType _imageMediaTypeFor(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return DioMediaType('image', 'png');
  if (lower.endsWith('.gif')) return DioMediaType('image', 'gif');
  if (lower.endsWith('.webp')) return DioMediaType('image', 'webp');
  if (lower.endsWith('.heic')) return DioMediaType('image', 'heic');
  if (lower.endsWith('.heif')) return DioMediaType('image', 'heif');
  return DioMediaType('image', 'jpeg');
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
    // Extract a basename for the part's Content-Disposition `filename=`
    // (multer rejects parts without one) and pick an `image/...`
    // Content-Type so multer's fileFilter accepts the part as a file.
    final basename =
        filePath.split(RegExp(r'[\\/]')).last.split('?').first;
    final filename = basename.isEmpty ? 'photo.jpg' : basename;
    final formData = FormData.fromMap({
      'param_index': paramIndex,
      'image': await MultipartFile.fromFile(
        filePath,
        filename: filename,
        contentType: _imageMediaTypeFor(filename),
      ),
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

  /// Bytes variant of [uploadParameterImage] for Flutter web, where
  /// `dart:io` File and `path_provider` aren't available so
  /// `MultipartFile.fromFile` can't be used. Otherwise identical — same
  /// endpoint, same response handling.
  Future<String?> uploadParameterImageBytes({
    required String auditId,
    required int paramIndex,
    required Uint8List bytes,
    required String filename,
  }) async {
    // On web some pickers hand back `XFile.name = ""` (camera captures,
    // certain browsers). Dio drops the part's `filename=` header when the
    // filename is empty, and multer then treats it as a plain form field
    // instead of a file — backend responds "Image is required". Fall back
    // to a sensible name + explicit image Content-Type so the part is
    // recognised regardless.
    final safeName = filename.isEmpty ? 'photo.jpg' : filename;
    final formData = FormData.fromMap({
      'param_index': paramIndex,
      'image': MultipartFile.fromBytes(
        bytes,
        filename: safeName,
        contentType: _imageMediaTypeFor(safeName),
      ),
    });
    return _sendUpload(auditId, formData);
  }

  /// POSTs the multipart upload and extracts the presigned (browser-loadable)
  /// URL from the response. Returns `null` when the backend only sent back an
  /// internal `s3://` URI — the upload still succeeded; the caller just won't
  /// be able to render it directly and keeps the local preview.
  Future<String?> _sendUpload(String auditId, FormData formData) async {
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
