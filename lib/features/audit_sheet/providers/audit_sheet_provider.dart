import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/audit_sheet_model.dart';
import '../services/audit_sheet_service.dart';

final auditSheetServiceProvider = Provider<AuditSheetService>(
  (ref) => AuditSheetService(ref.watch(apiServiceProvider)),
);

final auditSheetProvider = ChangeNotifierProvider<AuditSheetProvider>(
  (ref) => AuditSheetProvider(ref.watch(auditSheetServiceProvider)),
);

class AuditSheetProvider extends ChangeNotifier {
  AuditSheetProvider(this._service);

  final AuditSheetService _service;

  AuditSheetModel? currentSheet;
  Map<int, AuditRowState> rowStates = {};
  bool isLoading = false;
  bool hasUnsavedChanges = false;

  int get passCount =>
      rowStates.values
          .where((row) => row.result == AppConstants.resultPass)
          .length;
  int get failCount =>
      rowStates.values
          .where((row) => row.result == AppConstants.resultFail)
          .length;
  int get auditedCount =>
      rowStates.values.where((row) => row.result != null).length;
  double get passPercent {
    final reviewed =
        rowStates.values
            .where(
              (row) =>
                  row.result == AppConstants.resultPass ||
                  row.result == AppConstants.resultFail,
            )
            .length;
    return reviewed == 0 ? 0 : (passCount / reviewed) * 100;
  }

  Future<void> loadSheet(
    String auditId, {
    String projectName = 'Audit Project',
    String auditorName = 'Auditor',
    String location = 'Site',
  }) async {
    if (currentSheet?.auditPlanId == auditId && rowStates.isNotEmpty) {
      return;
    }

    isLoading = true;
    notifyListeners();
    try {
      currentSheet = await _service.getSheet(auditId);
    } catch (_) {
      currentSheet = _service.emptyTemplate(
        auditId: auditId,
        projectName: projectName,
        auditorName: auditorName,
        location: location,
      );
    } finally {
      rowStates = {
        for (final parameter in currentSheet!.parameters)
          parameter.index: AuditRowState(
            result: parameter.result,
            remark: parameter.remark,
            imagePath: parameter.imageUrl,
          ),
      };
      isLoading = false;
      notifyListeners();
    }
  }

  void setResult(int index, String result) {
    rowStates[index] = (rowStates[index] ?? const AuditRowState()).copyWith(
      result: result,
    );
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void setRemark(int index, String remark) {
    rowStates[index] = (rowStates[index] ?? const AuditRowState()).copyWith(
      remark: remark,
    );
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void setImage(int index, String imagePath) {
    rowStates[index] = (rowStates[index] ?? const AuditRowState()).copyWith(
      imagePath: imagePath,
    );
    hasUnsavedChanges = true;
    notifyListeners();
  }

  bool isRowComplete(int index) {
    final row = rowStates[index];
    return row != null &&
        row.result != null &&
        row.result!.isNotEmpty &&
        row.remark.trim().isNotEmpty;
  }

  List<int> incompleteRows() {
    return currentSheet?.parameters
            .where((parameter) => !isRowComplete(parameter.index))
            .map((parameter) => parameter.index)
            .toList() ??
        [];
  }

  Future<void> saveDraft() async {
    if (currentSheet == null) return;
    isLoading = true;
    notifyListeners();
    try {
      currentSheet = await _service.updateSheet(
        auditId: currentSheet!.auditPlanId,
        data: _rowPayload(),
      );
      hasUnsavedChanges = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitSheet() async {
    if (currentSheet == null) return;
    isLoading = true;
    notifyListeners();
    try {
      await _service.updateSheet(
        auditId: currentSheet!.auditPlanId,
        data: _rowPayload(),
      );
      await _service.submitSheet(currentSheet!.auditPlanId);
      hasUnsavedChanges = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _rowPayload() {
    final parameters = currentSheet?.parameters ?? [];
    return parameters
        .map(
          (parameter) => (rowStates[parameter.index] ?? const AuditRowState())
              .toJson(parameter.index, parameter.name),
        )
        .toList();
  }
}
