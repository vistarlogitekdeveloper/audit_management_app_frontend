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

    final isExternal = (url.startsWith('http://') ||
            url.startsWith('https://')) &&
        !url.startsWith(ApiConstants.baseUrl);
    if (isExternal) {
      // A pre-signed storage URL (e.g. S3) — must NOT carry our API auth
      // header, and it already includes its own credentials.
      await Dio().download(url, path);
    } else {
      // Backend-hosted (relative or same-origin) — needs the base URL and
      // the Authorization header from the shared client.
      await _apiService.dio.download(url, path);
    }
    return path;
  }
}
