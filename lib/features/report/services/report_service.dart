import 'dart:convert';
import 'dart:io';

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

    // Backend returns one of three URL shapes depending on env:
    //  - S3 presigned (external https://…amazonaws.com/…) — needs a fresh
    //    Dio without our Authorization header
    //  - backend-hosted (relative or same-origin as our API baseUrl) —
    //    reuse the authenticated client
    //  - data:application/pdf;base64,… — no HTTP fetch at all, decode the
    //    base64 payload and write bytes to disk directly. This is the
    //    fallback when AWS_S3_BUCKET isn't set on the API deploy; the old
    //    dio.download path would silently fail against a data URL.
    if (url.startsWith('data:')) {
      final commaIdx = url.indexOf(',');
      if (commaIdx < 0) throw Exception('Malformed data URL for PDF');
      final base64Part = url.substring(commaIdx + 1);
      final bytes = base64Decode(base64Part);
      await File(path).writeAsBytes(bytes, flush: true);
      return path;
    }

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
