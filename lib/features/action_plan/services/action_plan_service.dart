import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/download_helper.dart';
import '../models/action_plan_model.dart';

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
              },
            )
            .toList(),
      },
    );
    return ActionPlanModel.fromJson(_apiService.extractObject(response));
  }

  /// Uploads one optional evidence file against a single action-plan point.
  /// The backend field name must be exactly `file` (multer .single('file')).
  /// Returns the created attachment (with its id + presigned display URL).
  /// [itemId] must be a persisted action item id.
  Future<ActionItemAttachment> uploadItemAttachment({
    required String planId,
    required String itemId,
    required List<int> bytes,
    String? filename,
    String? mimeType,
  }) async {
    final response = await _apiService.postMultipart(
      ApiConstants.actionPlanItemAttachments(planId, itemId),
      fileField: 'file',
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );
    return ActionItemAttachment.fromJson(_apiService.extractObject(response));
  }

  /// Deletes one previously-uploaded attachment. The backend only lets the
  /// uploading owner (or an admin) remove it.
  Future<void> deleteItemAttachment({
    required String planId,
    required String itemId,
    required String attachmentId,
  }) async {
    await _apiService.delete(
      ApiConstants.actionPlanItemAttachment(planId, itemId, attachmentId),
    );
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

  /// Requests a PDF render of the plan from the backend and hands off to
  /// the shared cross-platform DownloadHelper: on web the file streams
  /// straight into the browser's downloads folder; on native it's written
  /// to a temp path exposed via [DownloadResult.savedPath].
  Future<DownloadResult> downloadActionPlanPdf(String planId) async {
    final response = await _apiService.get(ApiConstants.actionPlanPdf(planId));
    final data = _apiService.extractObject(response);
    final url = data['pdf_url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('PDF URL not available');
    }

    final isExternal =
        (url.startsWith('http://') || url.startsWith('https://')) &&
            !url.startsWith(ApiConstants.baseUrl);
    // Presigned S3 URLs already carry their own credentials, so use a bare
    // Dio without the API's Authorization header. Backend-hosted URLs go
    // through the shared client so they pick up the base URL + auth.
    final client = isExternal ? Dio() : _apiService.dio;
    final resp = await client.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = Uint8List.fromList(resp.data ?? <int>[]);

    return DownloadHelper.save(
      filename: 'action-plan-$planId.pdf',
      bytes: bytes,
      mimeType: 'application/pdf',
    );
  }
}
