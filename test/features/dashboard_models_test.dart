import 'package:audit_management_app_frontend/features/dashboard/models/auditor_owner_dashboard_model.dart';
import 'package:audit_management_app_frontend/features/dashboard/models/dashboard_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression for the HIGH unsafe-cast bug in the dashboard models: `item as
/// Map<String,dynamic>` threw on any non-map list element / non-map `stats`,
/// and the analyzer-flagged dead `?? ''` in OwnerAuditReview.
void main() {
  group('AdminDashboardModel.fromJson', () {
    test('tolerates non-map stats and bad list elements', () {
      final json = {
        'stats': 'not-a-map',
        'upcomingAudits': [
          {'id': 'u1'},
          null,
        ],
        'clusterPassRates': [
          {'cluster_id': 'c1', 'cluster_name': 'North', 'pass_rate': 80},
          'garbage',
        ],
        'recentActivity': null,
        'allProjects': [
          {'id': 'p1', 'name': 'Acme'},
        ],
      };

      final model = AdminDashboardModel.fromJson(json);

      expect(model.stats.totalPlanned, 0); // non-map stats -> defaults
      expect(model.upcomingAudits, hasLength(1));
      expect(model.clusterPassRates, hasLength(1));
      expect(model.clusterPassRates.first.clusterName, 'North');
      expect(model.recentActivity, isEmpty);
      expect(model.allProjects.single.name, 'Acme');
    });
  });

  group('AuditorDashboardModel.fromJson', () {
    test('skips non-map elements in myAudits', () {
      final json = {
        'stats': {'assignedToMe': 2},
        'myAudits': [
          {'id': 'a1', 'status': 'released'},
          'oops',
          null,
        ],
      };

      final model = AuditorDashboardModel.fromJson(json);
      expect(model.assignedCount, 2);
      expect(model.audits, hasLength(1));
      expect(model.audits.single.id, 'a1');
    });
  });

  group('OwnerDashboardModel.fromJson', () {
    test('parses awaiting list with mixed shapes', () {
      final json = {
        'stats': {'awaitingReview': 1},
        'awaitingAcknowledgement': [
          {
            'id': 'r1',
            'project': {'name': 'Acme'},
            'auditor': 'Bob',
          },
          null,
        ],
        'actionPlans': [
          {
            'id': 'pl1',
            'project': 'Acme',
            'failPoints': 3,
            'dueDate': '2026-06-01',
            'daysRemaining': 2,
          },
        ],
      };

      final model = OwnerDashboardModel.fromJson(json);
      expect(model.awaitingReview, 1);
      expect(model.auditsAwaiting, hasLength(1));
      // project as embedded map, auditor as plain string -> both resolved
      // (the removed dead `?? ''` must not change this behaviour).
      expect(model.auditsAwaiting.single.project, 'Acme');
      expect(model.auditsAwaiting.single.auditor, 'Bob');
      expect(model.actionPlans.single.daysRemaining, 2);
    });

    test('OwnerAuditReview handles project as plain string', () {
      final review = OwnerAuditReview.fromJson({
        'id': 'r2',
        'project': 'Plain Project',
        'auditor': {'name': 'Alice'},
      });
      expect(review.project, 'Plain Project');
      expect(review.auditor, 'Alice');
    });

    test('drops already-acknowledged audits from auditsAwaiting even when the '
        'backend still returns them in the awaitingAcknowledgement list', () {
      final json = {
        'stats': {'awaitingReview': 3},
        'awaitingAcknowledgement': [
          {
            'id': 'a-pending',
            'project': {'name': 'P1'},
            'auditor': 'Bob',
            'AuditSheet': {'status': 'submitted'},
          },
          {
            'id': 'a-acked',
            'project': {'name': 'P2'},
            'auditor': 'Bob',
            'AuditSheet': {'status': 'acknowledged'},
          },
          {
            // No AuditSheet block at all — must NOT be dropped (treated
            // as "status unknown, trust the backend").
            'id': 'a-no-sheet',
            'project': {'name': 'P3'},
            'auditor': 'Bob',
          },
        ],
        'actionPlans': [],
      };
      final model = OwnerDashboardModel.fromJson(json);
      expect(model.auditsAwaiting.map((a) => a.id),
          ['a-pending', 'a-no-sheet']);
      // Headline counter never grows past the backend's number, but it
      // shrinks to match the filtered list so the tile can't disagree
      // with what's rendered below it.
      expect(model.awaitingReview, 2);
    });

    test('drops submitted / closed action plans from the Open list', () {
      final json = {
        'stats': {'actionPlanDue': 4},
        'awaitingAcknowledgement': [],
        'actionPlans': [
          {
            'id': 'p-pending',
            'project': 'P1',
            'failPoints': 2,
            'dueDate': '2026-06-01',
            'daysRemaining': 3,
            'status': 'pending',
          },
          {
            'id': 'p-submitted',
            'project': 'P2',
            'failPoints': 1,
            'dueDate': '2026-06-01',
            'daysRemaining': 1,
            'status': 'submitted',
          },
          {
            'id': 'p-closed',
            'project': 'P3',
            'failPoints': 0,
            'dueDate': '2026-06-01',
            'daysRemaining': -1,
            'status': 'closed',
          },
        ],
      };
      final model = OwnerDashboardModel.fromJson(json);
      expect(model.actionPlans.map((p) => p.id), ['p-pending']);
      expect(model.actionPlanDue, 1);
    });
  });
}
