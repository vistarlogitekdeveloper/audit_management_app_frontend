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

  Future<AuditSheetModel> getSheet(String auditId) async {
    final response = await _apiService.get(ApiConstants.auditSheet(auditId));
    return AuditSheetModel.fromJson(_apiService.extractObject(response));
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
