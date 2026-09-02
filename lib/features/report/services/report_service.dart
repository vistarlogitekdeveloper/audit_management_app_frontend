import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/download_helper.dart';
import '../models/report_model.dart';

class ReportService {
  ReportService(this._apiService);

  final ApiService _apiService;

  Future<ReportModel> getReport(String auditId) async {
    final response = await _apiService.get(ApiConstants.report(auditId));
    return ReportModel.fromJson(_apiService.extractObject(response));
  }

  /// Downloads the report PDF and hands it to the cross-platform
  /// [DownloadHelper]: on web it streams into the browser's downloads folder
  /// and `savedPath` is null; on native it writes to a temp file whose path
  /// the screen can pass to a PDFView preview.
  Future<DownloadResult> downloadReportPDF(String auditId) async {
    final response = await _apiService.get(ApiConstants.reportPdf(auditId));
    final data = _apiService.extractObject(response);
    final url = data['pdf_url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('PDF URL not available');
    }

    // Three URL shapes possible from the API depending on env:
    //  - data:application/pdf;base64,… — decode inline, no HTTP fetch
    //  - external presigned (S3 etc.) — bare Dio without our auth header
    //  - same-origin backend URL — authenticated Dio via shared client
    Uint8List bytes;
    if (url.startsWith('data:')) {
      final commaIdx = url.indexOf(',');
      if (commaIdx < 0) {
        throw Exception('Malformed data URL for PDF');
      }
      bytes = base64Decode(url.substring(commaIdx + 1));
    } else {
      final isExternal =
          (url.startsWith('http://') || url.startsWith('https://')) &&
              !url.startsWith(ApiConstants.baseUrl);
      final client = isExternal ? Dio() : _apiService.dio;
      final resp = await client.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      bytes = Uint8List.fromList(resp.data ?? <int>[]);
    }

    return DownloadHelper.save(
      filename: 'audit-report-$auditId.pdf',
      bytes: bytes,
      mimeType: 'application/pdf',
    );
  }
}
