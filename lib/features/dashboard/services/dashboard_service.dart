import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/auditor_owner_dashboard_model.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  DashboardService(this._apiService);

  final ApiService _apiService;

  Future<AdminDashboardModel> getAdminDashboard() async {
    final response = await _apiService.get(ApiConstants.adminDashboard);
    final data = _apiService.extractObject(response);
    return AdminDashboardModel.fromJson(data);
  }

  Future<AuditorDashboardModel> getAuditorDashboard() async {
    final response = await _apiService.get(ApiConstants.auditorDashboard);
    final data = _apiService.extractObject(response);
    return AuditorDashboardModel.fromJson(data);
  }

  Future<OwnerDashboardModel> getOwnerDashboard() async {
    final response = await _apiService.get(ApiConstants.ownerDashboard);
    final data = _apiService.extractObject(response);
    return OwnerDashboardModel.fromJson(data);
  }

  Future<OwnerDashboardModel> getClusterDashboard() async {
    final response = await _apiService.get(ApiConstants.clusterDashboard);
    final data = _apiService.extractObject(response);
    return OwnerDashboardModel.fromJson(data);
  }
}
