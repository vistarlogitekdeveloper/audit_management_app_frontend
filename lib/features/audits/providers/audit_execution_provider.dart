import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/audit_repository.dart';

part 'audit_execution_provider.g.dart';

@riverpod
class AuditQuestionsNotifier extends _$AuditQuestionsNotifier {
  @override
  Stream<List<AuditQuestion>> build(String auditPlanId) {
    ref.read(auditRepositoryProvider).fetchAndSyncAuditQuestions(auditPlanId).catchError((_) {
      // Ignored for offline mode
    });
    return ref.watch(auditRepositoryProvider).watchAuditQuestions(auditPlanId);
  }
}

@riverpod
class AuditResponsesNotifier extends _$AuditResponsesNotifier {
  @override
  Stream<List<AuditResponse>> build(String auditPlanId) {
    final db = ref.watch(appDatabaseProvider);
    return (db.select(db.auditResponses)..where((t) => t.auditPlanId.equals(auditPlanId))).watch();
  }

  Future<void> saveResponse({
    required String auditPlanId,
    required String questionId,
    required String status,
    String? remarks,
    String? imagePath,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final storage = ref.read(secureStorageProvider);
    final deviceId = await storage.getDeviceId() ?? const Uuid().v4();

    // Check if response exists locally
    final existingResponse = await (db.select(db.auditResponses)
          ..where((t) => t.auditPlanId.equals(auditPlanId) & t.questionId.equals(questionId)))
        .getSingleOrNull();

    final companion = AuditResponsesCompanion(
      auditPlanId: Value(auditPlanId),
      questionId: Value(questionId),
      status: Value(status),
      remarks: remarks != null ? Value(remarks) : const Value.absent(),
      imagePath: imagePath != null ? Value(imagePath) : const Value.absent(),
      isSynced: const Value(false),
      updatedAt: Value(DateTime.now()),
    );

    if (existingResponse != null) {
      // Update
      await (db.update(db.auditResponses)
            ..where((t) => t.clientTempId.equals(existingResponse.clientTempId)))
          .write(companion);
    } else {
      // Insert
      await db.into(db.auditResponses).insert(
            companion.copyWith(
              clientTempId: Value(const Uuid().v4()),
              deviceId: Value(deviceId),
            ),
          );
    }
  }
}

@riverpod
class ActionPlansNotifier extends _$ActionPlansNotifier {
  @override
  Stream<List<ActionPlan>> build(String auditPlanId) {
    // Watch action plans related to responses of this audit plan.
    // For simplicity, we can fetch all action plans but we need joining in a real app.
    // Assuming we just fetch based on response ID later.
    final db = ref.watch(appDatabaseProvider);
    return db.select(db.actionPlans).watch();
  }

  Future<void> saveActionPlan({
    required String auditResponseId,
    required String description,
    DateTime? dueDate,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final storage = ref.read(secureStorageProvider);
    final deviceId = await storage.getDeviceId() ?? const Uuid().v4();

    await db.into(db.actionPlans).insert(
      ActionPlansCompanion(
        clientTempId: Value(const Uuid().v4()),
        deviceId: Value(deviceId),
        auditResponseId: Value(auditResponseId),
        description: Value(description),
        dueDate: dueDate != null ? Value(dueDate) : const Value.absent(),
        status: const Value('PENDING'),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
