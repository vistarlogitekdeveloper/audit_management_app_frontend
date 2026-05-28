import 'package:flutter_test/flutter_test.dart';

import 'package:audit_management_app_frontend/features/audit_plan/models/audit_plan_model.dart';

void main() {
  group('ProjectLookupModel.fromJson', () {
    test('extracts names/ids/emails from nested incharge & clusterManager '
        'objects (the real GET /projects shape)', () {
      final project = ProjectLookupModel.fromJson({
        'id': '909f3703-9d5d-4f2c-91b4-2c910fe40c7e',
        'name': 'ABC',
        'location': 'Pune',
        'client_name': null,
        'project_incharge_id': 'e9de765f-178f-47d8-a73e-506563d1bbc9',
        'incharge': {
          'id': 'e9de765f-178f-47d8-a73e-506563d1bbc9',
          'name': 'Nikhil Kulkarni',
          'email': 'nikhil.incharge@vistar.com',
        },
        'cluster_manager_id': '4ba24f0c-0ef3-4a62-9541-e0f5572fd026',
        'clusterManager': {
          'id': '4ba24f0c-0ef3-4a62-9541-e0f5572fd026',
          'name': 'Pallavi Naik',
          'email': 'pallavi.pm@vistar.com',
        },
      });

      expect(project.inchargeName, 'Nikhil Kulkarni');
      expect(project.inchargeEmail, 'nikhil.incharge@vistar.com');
      expect(project.inchargeId, 'e9de765f-178f-47d8-a73e-506563d1bbc9');
      expect(project.clusterManagerName, 'Pallavi Naik');
      expect(project.clusterManagerEmail, 'pallavi.pm@vistar.com');
      expect(project.clusterManagerId, '4ba24f0c-0ef3-4a62-9541-e0f5572fd026');
      // Must never surface a stringified map.
      expect(project.clusterManagerName.contains('{'), isFalse);
    });

    test('falls back to flat string fields when objects are absent', () {
      final project = ProjectLookupModel.fromJson({
        'id': 'p1',
        'name': 'Legacy',
        'projectIncharge': 'Old Incharge',
        'clusterManager': 'Old Cluster',
        'location': 'Nagpur',
      });

      expect(project.inchargeName, 'Old Incharge');
      expect(project.clusterManagerName, 'Old Cluster');
    });

    test('leaves names empty (not a map string) when associations are missing',
        () {
      final project = ProjectLookupModel.fromJson({
        'id': 'p2',
        'name': 'No assoc',
        'location': 'Goa',
      });

      expect(project.inchargeName, '');
      expect(project.clusterManagerName, '');
    });
  });
}
