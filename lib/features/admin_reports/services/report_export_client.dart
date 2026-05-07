import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/download_helper.dart';

class ReportExportClient {
  ReportExportClient(this._api);

  final ApiService _api;

  /// Filter map matches the admin reports filter UI:
  ///   { from_date, to_date, project_id, cluster_manager_id, status }
  Future<DownloadResult> downloadCsv(Map<String, dynamic> filters) {
    return _download(
      path: ApiConstants.exportReportsCsv,
      filename: _filename('csv'),
      mimeType: 'text/csv',
      filters: filters,
    );
  }

  Future<DownloadResult> downloadXlsx(Map<String, dynamic> filters) {
    return _download(
      path: ApiConstants.exportReportsXlsx,
      filename: _filename('xlsx'),
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      filters: filters,
    );
  }

  Future<DownloadResult> downloadPdf(Map<String, dynamic> filters) {
    return _download(
      path: ApiConstants.exportReportsPdf,
      filename: _filename('pdf'),
      mimeType: 'application/pdf',
      filters: filters,
    );
  }

  Future<DownloadResult> _download({
    required String path,
    required String filename,
    required String mimeType,
    required Map<String, dynamic> filters,
  }) async {
    final cleaned = <String, dynamic>{};
    filters.forEach((k, v) {
      if (v == null) return;
      if (v is String && v.isEmpty) return;
      cleaned[k] = v;
    });
    final response = await _api.dio.get<List<int>>(
      path,
      queryParameters: cleaned,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = Uint8List.fromList(response.data ?? <int>[]);
    return DownloadHelper.save(
      filename: filename,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  String _filename(String ext) {
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('T', '_')
        .split('.')
        .first;
    return 'audit-report-$ts.$ext';
  }
}

final reportExportClientProvider = Provider<ReportExportClient>(
  (ref) => ReportExportClient(ref.watch(apiServiceProvider)),
);
