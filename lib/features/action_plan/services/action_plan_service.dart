import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/action_plan_model.dart';

/// Mirrors the audit-sheet helper — multer rejects multipart parts with no
/// Content-Type, which surfaces as "Image is required". Default jpeg because
/// that's what every picker hands back when the filename is missing.
DioMediaType _imageMediaTypeFor(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return DioMediaType('image', 'png');
  if (lower.endsWith('.gif')) return DioMediaType('image', 'gif');
  if (lower.endsWith('.webp')) return DioMediaType('image', 'webp');
  if (lower.endsWith('.heic')) return DioMediaType('image', 'heic');
  if (lower.endsWith('.heif')) return DioMediaType('image', 'heif');
  return DioMediaType('image', 'jpeg');
}

class ActionPlanService {
  ActionPlanService(this._apiService);

  final ApiService _apiService;

  /// Fetch the action plan auto-created by /audit-sheets/:id/acknowledge.
  /// Returns null if the plan does not exist yet.
  Future<ActionPlanModel?> getActionPlan(String auditSheetId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.actionPlanByAuditSheet(auditSheetId),
      );
      if (response == null) return null;
      return ActionPlanModel.fromJson(_apiService.extractObject(response));
    } on ApiException catch (e) {
      // 404 == no plan exists for this sheet yet → null. Let real failures
      // (network/5xx) propagate so the provider can surface them instead of
      // masking everything as "no plan".
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  /// Save items into an existing plan. Use the plan id (NOT the audit-sheet id).
  /// Backend validation requires every item to carry a real audit_parameter_id.
  ///
  /// `images` is the full per-item URL list as the client currently sees it.
  /// Sending it lets the owner remove a photo client-side and have the change
  /// stick — the alternative (omit `images` and trust the backend) means a
  /// remove-then-save is silently undone on the next fetch.
  Future<ActionPlanModel> updateActionPlan({
    required String planId,
    required List<ActionItemModel> items,
  }) async {
    final response = await _apiService.patch(
      ApiConstants.actionPlanById(planId),
      data: {
        'items': items
            .map(
              (item) => {
                'audit_parameter_id': item.auditParameterId,
                'fail_point': item.parameterName,
                'corrective_action': item.correctiveAction,
                'responsible_person': item.responsiblePerson,
                'due_date': item.dueDate.toIso8601String().split('T').first,
                'status': item.statusForApi,
                // Only the http(s) entries — local blob:/file paths haven't
                // been flushed yet and would just confuse the backend if
                // round-tripped as-is.
                'images': item.imagePaths
                    .where((p) => p.startsWith('http'))
                    .toList(),
              },
            )
            .toList(),
      },
    );
    return ActionPlanModel.fromJson(_apiService.extractObject(response));
  }

  /// Native upload — owner attaches an evidence photo to a single corrective
  /// item. Returns a browser-loadable URL (presigned) on success, or `null`
  /// when the backend stored the file but didn't surface a public URL.
  Future<String?> uploadActionItemImage({
    required String planId,
    required String itemId,
    required String filePath,
  }) async {
    final basename =
        filePath.split(RegExp(r'[\\/]')).last.split('?').first;
    final filename = basename.isEmpty ? 'photo.jpg' : basename;
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        filePath,
        filename: filename,
        contentType: _imageMediaTypeFor(filename),
      ),
    });
    final response = await _apiService.upload(
      ApiConstants.actionPlanItemUploadImage(planId, itemId),
      formData: formData,
    );
    return _firstHttpUrl(_apiService.extractObject(response));
  }

  /// Bytes variant for Flutter web — `dart:io` File-based uploads aren't
  /// available there, and some browser pickers ship empty `XFile.name`
  /// values that multer would otherwise treat as a non-file form field.
  Future<String?> uploadActionItemImageBytes({
    required String planId,
    required String itemId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final safeName = filename.isEmpty ? 'photo.jpg' : filename;
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        bytes,
        filename: safeName,
        contentType: _imageMediaTypeFor(safeName),
      ),
    });
    final response = await _apiService.upload(
      ApiConstants.actionPlanItemUploadImage(planId, itemId),
      formData: formData,
    );
    return _firstHttpUrl(_apiService.extractObject(response));
  }

  String? _firstHttpUrl(Map<String, dynamic> data) {
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

  /// Auditor verdict on a single item. [reviewStatus] is 'approved' or
  /// 'rejected'; [remark] is required when rejecting. Returns the updated
  /// item only (same shape as items in GET /action-plans/:auditSheetId).
  Future<ActionItemModel> reviewItem({
    required String planId,
    required String itemId,
    required String reviewStatus,
    String? remark,
  }) async {
    final response = await _apiService.patch(
      ApiConstants.actionPlanItemReview(planId, itemId),
      data: {
        'review_status': reviewStatus,
        if (remark != null && remark.trim().isNotEmpty) 'remark': remark.trim(),
      },
    );
    return ActionItemModel.fromJson(_apiService.extractObject(response));
  }

  /// Auditor closes the plan. Backend 409s if any item is not approved.
  Future<ActionPlanModel> closePlan({
    required String planId,
    String? remark,
  }) async {
    final response = await _apiService.post(
      ApiConstants.actionPlanClose(planId),
      data: {
        if (remark != null && remark.trim().isNotEmpty) 'remark': remark.trim(),
      },
    );
    return ActionPlanModel.fromJson(_apiService.extractObject(response));
  }
}
