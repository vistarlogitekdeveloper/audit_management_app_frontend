import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/db/app_database.dart';
import '../../../core/storage/secure_storage.dart';

part 'audit_repository.g.dart';

class AuditRepository {
  final Dio _dio;
  final AppDatabase _db;
  final SecureStorage _storage;

  AuditRepository(this._dio, this._db, this._storage);

  /// Fetch Audit Plans from server and sync to local Drift DB.
  Future<void> fetchAndSyncAuditPlans() async {
    try {
      final response = await _dio.get('/audit-plans');
      if (response.statusCode == 200) {
        final List plans = response.data['data'] ?? [];
        final deviceId = await _storage.getDeviceId() ?? const Uuid().v4();

        await _db.transaction(() async {
          for (final planData in plans) {
            // Check if plan exists locally by server ID
            final existingPlan = await (_db.select(_db.auditPlans)
                  ..where((t) => t.id.equals(planData['id'])))
                .getSingleOrNull();

            final companion = AuditPlansCompanion(
              id: Value(planData['id']),
              name: Value(planData['name']),
              description: Value(planData['description']),
              status: Value(planData['status']),
              startDate: planData['start_date'] != null 
                  ? Value(DateTime.parse(planData['start_date'])) 
                  : const Value.absent(),
              endDate: planData['end_date'] != null 
                  ? Value(DateTime.parse(planData['end_date'])) 
                  : const Value.absent(),
              isSynced: const Value(true), // coming from server, so considered synced
              updatedAt: Value(DateTime.now()),
            );

            if (existingPlan != null) {
              await (_db.update(_db.auditPlans)
                    ..where((t) => t.id.equals(planData['id'])))
                  .write(companion);
            } else {
              await _db.into(_db.auditPlans).insert(
                    companion.copyWith(
                      clientTempId: Value(const Uuid().v4()),
                      deviceId: Value(deviceId),
                    ),
                  );
            }
          }
        });
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch audit plans');
      }
      throw Exception('Unexpected error fetching audit plans');
    }
  }

  /// Fetch Audit Questions for a plan and sync locally
  Future<void> fetchAndSyncAuditQuestions(String auditPlanId) async {
    try {
      final response = await _dio.get('/audit-plans/$auditPlanId');
      if (response.statusCode == 200) {
        final planData = response.data['data'];
        final List questions = planData['questions'] ?? [];
        final deviceId = await _storage.getDeviceId() ?? const Uuid().v4();

        await _db.transaction(() async {
          for (final q in questions) {
            final existingQuestion = await (_db.select(_db.auditQuestions)
                  ..where((t) => t.id.equals(q['id'])))
                .getSingleOrNull();

            final companion = AuditQuestionsCompanion(
              id: Value(q['id']),
              auditPlanId: Value(auditPlanId),
              questionText: Value(q['question_text'] ?? q['text'] ?? ''),
              category: Value(q['category'] ?? 'General'),
              isRequired: Value(q['is_required'] ?? true),
              isSynced: const Value(true),
              updatedAt: Value(DateTime.now()),
            );

            if (existingQuestion != null) {
              await (_db.update(_db.auditQuestions)
                    ..where((t) => t.id.equals(q['id'])))
                  .write(companion);
            } else {
              await _db.into(_db.auditQuestions).insert(
                    companion.copyWith(
                      clientTempId: Value(const Uuid().v4()),
                      deviceId: Value(deviceId),
                    ),
                  );
            }
          }
        });
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch questions');
      }
      throw Exception('Unexpected error fetching questions');
    }
  }

  /// Watch local Audit Plans
  Stream<List<AuditPlan>> watchAuditPlans({String? statusFilter}) {
    final query = _db.select(_db.auditPlans);
    
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query.where((t) => t.status.equals(statusFilter));
    }
    
    return query.watch();
  }

  /// Watch local Audit Questions
  Stream<List<AuditQuestion>> watchAuditQuestions(String auditPlanId) {
    return (_db.select(_db.auditQuestions)
          ..where((t) => t.auditPlanId.equals(auditPlanId)))
        .watch();
  }
}


@riverpod
AuditRepository auditRepository(AuditRepositoryRef ref) {
  return AuditRepository(
    ref.watch(dioClientProvider).dio,
    ref.watch(appDatabaseProvider),
    ref.watch(secureStorageProvider),
  );
}
