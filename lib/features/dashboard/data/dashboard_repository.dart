import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';

part 'dashboard_repository.g.dart';

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<Map<String, dynamic>> fetchSummary() async {
    try {
      final response = await _dio.get('/dashboard/summary');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch summary');
      }
      throw Exception('Unexpected error fetching summary');
    }
  }

  Future<Map<String, dynamic>> fetchAuditStats() async {
    try {
      final response = await _dio.get('/dashboard/audit-stats');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch audit stats');
      }
      throw Exception('Unexpected error fetching audit stats');
    }
  }
}

@riverpod
DashboardRepository dashboardRepository(DashboardRepositoryRef ref) {
  return DashboardRepository(ref.watch(dioClientProvider).dio);
}
