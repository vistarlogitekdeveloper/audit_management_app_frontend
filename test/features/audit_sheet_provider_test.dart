import 'dart:async';

import 'package:audit_management_app_frontend/features/audit_sheet/models/audit_parameter_model.dart';
import 'package:audit_management_app_frontend/features/audit_sheet/models/audit_sheet_model.dart';
import 'package:audit_management_app_frontend/features/audit_sheet/providers/audit_sheet_provider.dart';
import 'package:audit_management_app_frontend/features/audit_sheet/services/audit_sheet_service.dart';
import 'package:flutter_test/flutter_test.dart';

AuditSheetModel _model(String id) => AuditSheetModel(
      id: id,
      auditPlanId: id,
      projectName: 'P',
      auditorName: 'A',
      location: 'L',
      auditDate: DateTime(2026, 1, 1),
      parameters: const [AuditParameterModel(index: 1, name: 'Param 1')],
    );

class _FakeAuditSheetService implements AuditSheetService {
  int getSheetCalls = 0;
  bool failFirstGetSheet = false;

  int updateCalls = 0;
  bool updateThrows = false;
  Completer<AuditSheetModel>? updateGate;

  int submitCalls = 0;

  @override
  Future<AuditSheetModel> getSheet(String auditId) async {
    getSheetCalls++;
    if (failFirstGetSheet && getSheetCalls == 1) {
      throw Exception('network down');
    }
    return _model('loaded-$auditId');
  }

  @override
  Future<AuditSheetModel> updateSheet({
    required String auditId,
    required List<Map<String, dynamic>> data,
    String status = 'draft',
  }) async {
    updateCalls++;
    if (updateThrows) throw Exception('save failed');
    if (updateGate != null) return updateGate!.future;
    return _model(auditId);
  }

  @override
  Future<void> submitSheet(String auditId) async {
    submitCalls++;
  }

  @override
  Future<AcknowledgeResult> acknowledgeSheet(
    String auditId,
    String ownerRemarks,
  ) async {
    return const AcknowledgeResult(hasFailPoints: false);
  }

  @override
  AuditSheetModel emptyTemplate({
    required String auditId,
    required String projectName,
    required String auditorName,
    required String location,
  }) {
    return _model(auditId);
  }
}

void main() {
  group('loadSheet (#2 stuck-blank + swallowed errors)', () {
    test('a failed fetch sets loadError, keeps a usable template, and retries',
        () async {
      final service = _FakeAuditSheetService()..failFirstGetSheet = true;
      final provider = AuditSheetProvider(service);

      await provider.loadSheet('A');

      // Fallback template surfaced, error recorded, screen gate satisfied.
      expect(provider.loadError, isNotNull);
      expect(provider.currentSheet, isNotNull);
      expect(provider.isLoadedFor('A'), isTrue);

      // A fallback must NOT short-circuit a later retry.
      await provider.loadSheet('A');

      expect(service.getSheetCalls, 2);
      expect(provider.loadError, isNull);
      expect(provider.currentSheet!.id, 'loaded-A');
    });

    test('isLoadedFor is false for an audit that has not been loaded',
        () async {
      final provider = AuditSheetProvider(_FakeAuditSheetService());
      expect(provider.isLoadedFor('Z'), isFalse);
      await provider.loadSheet('A');
      expect(provider.isLoadedFor('A'), isTrue);
      expect(provider.isLoadedFor('B'), isFalse);
    });
  });

  group('saveDraft / submitSheet (#8 double-submit guard)', () {
    test('a second saveDraft while one is in flight is ignored', () async {
      final service = _FakeAuditSheetService();
      final provider = AuditSheetProvider(service);
      await provider.loadSheet('A');

      service.updateGate = Completer<AuditSheetModel>();

      final first = provider.saveDraft(); // in flight
      final second = await provider.saveDraft(); // guarded -> false

      expect(second, isFalse);
      expect(service.updateCalls, 1);

      service.updateGate!.complete(_model('A'));
      expect(await first, isTrue);
    });

    test('saveDraft returns false and records actionError on failure',
        () async {
      final service = _FakeAuditSheetService()..updateThrows = true;
      final provider = AuditSheetProvider(service);
      await provider.loadSheet('A');

      final ok = await provider.saveDraft();

      expect(ok, isFalse);
      expect(provider.actionError, isNotNull);
      expect(provider.isLoading, isFalse);
    });

    test('successful submit calls update then submit and clears errors',
        () async {
      final service = _FakeAuditSheetService();
      final provider = AuditSheetProvider(service);
      await provider.loadSheet('A');

      final ok = await provider.submitSheet();

      expect(ok, isTrue);
      expect(service.updateCalls, 1);
      expect(service.submitCalls, 1);
      expect(provider.actionError, isNull);
    });
  });
}
