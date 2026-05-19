import 'package:audit_management_app_frontend/features/report/models/report_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression for the HIGH unsafe-cast bug: ReportModel.fromJson used
/// `as Map<String,dynamic>` casts that threw TypeError when the backend sent
/// `clusterManager` as a plain string, or a non-map element inside the
/// parameters list.
void main() {
  group('ReportModel.fromJson (nested/production shape)', () {
    test('does not throw when clusterManager is a string', () {
      final json = {
        'auditPlan': {'id': 'ap1', 'audit_date': '2026-01-02', 'location': 'X'},
        'project': {'name': 'Acme', 'clusterManager': 'Jane Doe'},
        'auditor': {'name': 'Bob'},
        'auditSheet': {
          'total_audited': 3,
          'total_pass': 2,
          'total_fail': 1,
          'pass_percent': 66.6,
          'parameters': [
            {'param_index': 1, 'param_name': 'P1', 'result': 'pass'},
          ],
        },
      };

      final report = ReportModel.fromJson(json);

      expect(report.auditId, 'ap1');
      expect(report.projectName, 'Acme');
      expect(report.auditorName, 'Bob');
      expect(report.parameters, hasLength(1));
      // String clusterManager degrades gracefully instead of crashing.
      expect(report.clusterManager, '');
    });

    test('extracts clusterManager name when it is a proper map', () {
      final json = {
        'auditPlan': {'id': 'ap2'},
        'project': {
          'name': 'Acme',
          'clusterManager': {'name': 'Cluster Boss'},
        },
        'auditor': {'name': 'Bob'},
        'auditSheet': {'parameters': []},
      };

      final report = ReportModel.fromJson(json);
      expect(report.clusterManager, 'Cluster Boss');
    });

    test('skips non-map elements in the parameters list', () {
      final json = {
        'auditPlan': {'id': 'ap3'},
        'project': {'name': 'Acme'},
        'auditSheet': {
          'parameters': [
            {'param_index': 1, 'param_name': 'Good'},
            null,
            'garbage',
            {'param_index': 2, 'param_name': 'AlsoGood'},
          ],
        },
      };

      final report = ReportModel.fromJson(json);
      expect(report.parameters.map((p) => p.name), ['Good', 'AlsoGood']);
    });
  });

  group('ReportModel.fromJson (legacy flat shape)', () {
    test('parses flat string clusterManager', () {
      final json = {
        'auditId': 'a1',
        'projectName': 'Flat Co',
        'auditorName': 'Sam',
        'date': '2026-03-04',
        'location': 'Site',
        'clusterManager': 'Flat Manager',
        'totalAudited': 1,
        'passCount': 1,
        'failCount': 0,
        'passPercent': 100,
        'parameters': [
          {'index': 1, 'name': 'P1', 'result': 'pass'},
        ],
      };

      final report = ReportModel.fromJson(json);
      expect(report.projectName, 'Flat Co');
      expect(report.clusterManager, 'Flat Manager');
      expect(report.parameters, hasLength(1));
    });
  });
}
