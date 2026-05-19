import 'package:audit_management_app_frontend/features/action_plan_tracker/models/action_plan_summary.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression for bug #7: the tracker opened the owner action-plan screen with
/// `auditPlanId` where the screen/service expect the audit *sheet* id. The fix
/// relies on ActionPlanSummary exposing BOTH ids, parsed from their distinct
/// backend keys. Also covers the asStringMap hardening of project/auditor.
void main() {
  test('parses audit_sheet_id and audit_plan_id into distinct fields', () {
    final summary = ActionPlanSummary.fromJson({
      'id': 'plan-1',
      'audit_sheet_id': 'sheet-99',
      'audit_plan_id': 'plan-77',
      'project': {'name': 'Acme', 'location': 'Site A'},
      'auditor': {'name': 'Bob'},
      'status': 'pending',
      'due_date': '2026-07-01',
      'daysRemaining': 5,
    });

    expect(summary.auditSheetId, 'sheet-99');
    expect(summary.auditPlanId, 'plan-77');
    expect(summary.auditSheetId, isNot(summary.auditPlanId));
    expect(summary.projectName, 'Acme');
    expect(summary.auditorName, 'Bob');
  });

  test('does not throw when project/auditor are missing or non-map', () {
    final summary = ActionPlanSummary.fromJson({
      'id': 'plan-2',
      'audit_sheet_id': 'sheet-1',
      'project': 'just-a-string',
    });

    expect(summary.projectName, '');
    expect(summary.auditorName, '');
    expect(summary.auditSheetId, 'sheet-1');
  });

  test('isOverdue / isClosed derive correctly', () {
    final overdue = ActionPlanSummary.fromJson({
      'id': 'p',
      'status': 'overdue',
      'daysRemaining': -3,
    });
    expect(overdue.isOverdue, isTrue);

    final closed = ActionPlanSummary.fromJson({
      'id': 'p',
      'status': 'pending',
      'items_total': 4,
      'items_closed': 4,
    });
    expect(closed.isClosed, isTrue);
  });
}
