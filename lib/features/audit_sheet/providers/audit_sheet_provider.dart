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

  /// Set when the last [loadSheet] fell back to a blank template because the
  /// fetch failed. The UI can surface this instead of silently showing an
  /// empty sheet.
  String? loadError;

  /// Set when the last [saveDraft]/[submitSheet] failed, so the screen can
  /// show the reason instead of a stuck spinner / silent failure.
  String? actionError;

  /// The audit id that was last loaded *successfully* from the backend. Only a
  /// successful fetch sets this, so a fallback template never short-circuits a
  /// later retry.
  String? _loadedAuditId;

  /// Audit id whose data currently populates [currentSheet]/[rowStates] —
  /// either a successful fetch or a fallback template. Lets a screen detect
  /// when the (singleton) provider still holds a *different* audit's sheet.
  String? _activeAuditId;

  String? get loadedAuditId => _loadedAuditId;

  /// True when the provider's loaded state corresponds to [auditId] (a real
  /// fetch or a fallback template built for it).
  bool isLoadedFor(String auditId) => _activeAuditId == auditId;

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
    // Only skip the fetch when this exact audit was previously loaded
    // *successfully*. A fallback template (network/parse failure) must never
    // short-circuit a later retry, otherwise the user is permanently stuck on
    // a blank sheet.
    if (_loadedAuditId == auditId && rowStates.isNotEmpty) {
      return;
    }

    isLoading = true;
    loadError = null;
    notifyListeners();

    AuditSheetModel? sheet;
    try {
      sheet = await _service.getSheet(auditId);
      _loadedAuditId = auditId;
    } catch (error) {
      // Surface the failure so the screen can show an error/retry instead of
      // a silently empty sheet, and leave _loadedAuditId unset so the next
      // navigation re-attempts the real fetch.
      loadError = _readableError(error);
      sheet = _service.emptyTemplate(
        auditId: auditId,
        projectName: projectName,
        auditorName: auditorName,
        location: location,
      );
    } finally {
      currentSheet = sheet;
      _activeAuditId = sheet == null ? null : auditId;
      rowStates = sheet == null
          ? {}
          : {
              for (final parameter in sheet.parameters)
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

  String _readableError(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ')
        ? text.substring('Exception: '.length)
        : text;
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

  /// Saves the current rows as a draft. Returns `true` on success. Re-entrant
  /// calls (rapid double-tap, or autosave racing a manual save) are ignored
  /// while a save/submit is already in flight, and failures are reported via
  /// [actionError] instead of escaping as an unhandled async error.
  Future<bool> saveDraft() async {
    if (currentSheet == null || isLoading) return false;
    isLoading = true;
    actionError = null;
    notifyListeners();
    try {
      currentSheet = await _service.updateSheet(
        auditId: currentSheet!.auditPlanId,
        data: _rowPayload(),
      );
      hasUnsavedChanges = false;
      // A successful round-trip means the sheet is synced again, so the
      // earlier "couldn't load" banner is no longer accurate.
      loadError = null;
      return true;
    } catch (error) {
      actionError = _readableError(error);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Persists the rows then submits the sheet. Returns `true` on success.
  /// Same re-entrancy/error semantics as [saveDraft].
  Future<bool> submitSheet() async {
    if (currentSheet == null || isLoading) return false;
    isLoading = true;
    actionError = null;
    notifyListeners();
    try {
      await _service.updateSheet(
        auditId: currentSheet!.auditPlanId,
        data: _rowPayload(),
      );
      await _service.submitSheet(currentSheet!.auditPlanId);
      hasUnsavedChanges = false;
      loadError = null;
      return true;
    } catch (error) {
      actionError = _readableError(error);
      return false;
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
