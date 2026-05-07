import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/report_model.dart';

class ReportService {
  ReportService(this._apiService);

  final ApiService _apiService;

  Future<ReportModel> getReport(String auditId) async {
    final response = await _apiService.get(ApiConstants.report(auditId));
    return ReportModel.fromJson(_apiService.extractObject(response));
  }

  Future<String> downloadReportPDF(String auditId) async {
    final response = await _apiService.get(ApiConstants.reportPdf(auditId));
    final data = _apiService.extractObject(response);
    final url = data['pdf_url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('PDF URL not available');
    }
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/audit_report_$auditId.pdf';
    await Dio().download(url, path);
    return path;
  }
}
