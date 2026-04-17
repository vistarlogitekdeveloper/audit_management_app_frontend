import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/dashboard_repository.dart';
import '../../../core/db/app_database.dart';

part 'dashboard_provider.g.dart';

@riverpod
Future<Map<String, dynamic>> dashboardSummary(DashboardSummaryRef ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return await repository.fetchSummary();
}

@riverpod
Future<int> pendingSyncCount(PendingSyncCountRef ref) async {
  final db = ref.watch(appDatabaseProvider);
  
  // Pending Audit Responses
  final pendingResponses = await (db.select(db.auditResponses)
        ..where((t) => t.isSynced.equals(false)))
      .get();
      
  // Pending Action Plans
  final pendingActionPlans = await (db.select(db.actionPlans)
        ..where((t) => t.isSynced.equals(false)))
      .get();

  return pendingResponses.length + pendingActionPlans.length;
}

@riverpod
Future<Map<String, dynamic>> auditStats(AuditStatsRef ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return await repository.fetchAuditStats();
}
