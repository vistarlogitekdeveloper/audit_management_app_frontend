import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../data/audit_repository.dart';

part 'audit_provider.g.dart';

@riverpod
class AuditPlansNotifier extends _$AuditPlansNotifier {
  @override
  Stream<List<AuditPlan>> build({String? statusFilter}) {
    // Attempt to fetch from network when we start watching the plans
    ref.read(auditRepositoryProvider).fetchAndSyncAuditPlans().catchError((error) {
      // Ignored here; offline mode will just show existing DB values
      print('Fetch audits failed, relying on local DB: $error');
    });
    
    return ref.watch(auditRepositoryProvider).watchAuditPlans(statusFilter: statusFilter);
  }
}
