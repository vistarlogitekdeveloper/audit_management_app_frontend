import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../models/auditor_owner_dashboard_model.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

final dashboardServiceProvider = Provider<DashboardService>(
  (ref) => DashboardService(ref.watch(apiServiceProvider)),
);

final adminDashboardProvider =
    FutureProvider<AdminDashboardModel>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getAdminDashboard();
});

final auditorDashboardProvider =
    FutureProvider<AuditorDashboardModel>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getAuditorDashboard();
});

final ownerDashboardProvider =
    FutureProvider<OwnerDashboardModel>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getOwnerDashboard();
});

final clusterDashboardProvider =
    FutureProvider<OwnerDashboardModel>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getClusterDashboard();
});
