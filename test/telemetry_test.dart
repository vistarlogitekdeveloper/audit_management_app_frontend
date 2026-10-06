import 'dart:convert';
import 'dart:typed_data';

import 'package:audit_management_app_frontend/core/telemetry/telemetry.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const uuid = '7f3c2a10-1b2c-4d5e-8f90-a1b2c3d4e5f6';
  const item = 'b2c3d4e5-f6a7-4b8c-9d0e-f1a2b3c4d5e6';
  // A uuid whose first block has no digit at all.
  const lettersUuid = 'abcdefab-cdef-4abc-8def-abcdefabcdef';

  test('screen names carry no audit, plan or item ids', () {
    expect(Telemetry.routePattern('/admin/dashboard'), '/admin/dashboard');
    expect(Telemetry.routePattern('/auditor/audit/$uuid'), '/auditor/audit/:id');
    expect(Telemetry.routePattern('/auditor/audit/$lettersUuid'), '/auditor/audit/:id');
    expect(Telemetry.routePattern('/owner/review/$uuid?tab=2'), '/owner/review/:id');
    expect(Telemetry.routePattern('/owner/action-plan/$uuid'), '/owner/action-plan/:id');
    expect(Telemetry.routePattern('/cluster/audit/$uuid'), '/cluster/audit/:id');
    expect(Telemetry.routePattern('/report/$uuid'), '/report/:id');
    expect(Telemetry.routePattern('/admin/create-plan'), '/admin/create-plan');
    expect(Telemetry.routePattern('/auditor/audit-details/42'), '/auditor/audit-details/:id');
    expect(Telemetry.routePattern('https://api.vistarlogitek.com/api/v1/audit/audit-sheets/$uuid'),
        '/api/v1/audit/audit-sheets/:id');
  });

  test('references with digits (project or site codes) become :ref', () {
    expect(Telemetry.routePattern('/projects/PRJ-2026-014'), '/projects/:ref');
    expect(Telemetry.routePattern('/reports/cluster/CM12'), '/reports/cluster/:ref');
    expect(Telemetry.routePattern('/audits/AUD%2F2026%2F0012/view'), '/audits/:ref/view');
    expect(Telemetry.routePattern('/reports/export.csv'), '/reports/export.csv');
  });

  test('the audit journey is named from successful writes', () {
    expect(Telemetry.actionFor('POST', '/audit-plans'), 'audit_plan_created');
    expect(Telemetry.actionFor('PATCH', '/audit-plans/release'), 'audit_plan_released');
    expect(Telemetry.actionFor('PATCH', '/audit-plans/$uuid/release'), 'audit_plan_released');
    expect(Telemetry.actionFor('PATCH', '/audit-plans/$uuid/reschedule'), 'audit_rescheduled');
    expect(Telemetry.actionFor('PATCH', '/audit-plans/$uuid'), 'audit_plan_updated');
    expect(Telemetry.actionFor('DELETE', '/audit-plans/$uuid/hard-delete'), 'audit_plan_deleted');
    expect(Telemetry.actionFor('DELETE', '/audit-plans/$uuid'), 'audit_plan_cancelled');
    expect(Telemetry.actionFor('POST', '/audit-sheets/$uuid/upload-image'), 'audit_photo_uploaded');
    expect(Telemetry.actionFor('POST', '/audit-sheets/$uuid/submit'), 'audit_submitted');
    expect(Telemetry.actionFor('POST', '/audit-sheets/$lettersUuid/acknowledge'), 'audit_acknowledged');
    expect(Telemetry.actionFor('PATCH', '/action-plans/$uuid'), 'action_plan_updated');
    expect(Telemetry.actionFor('POST', '/action-plans/$uuid/items/$item/attachments'), 'action_evidence_uploaded');
    expect(Telemetry.actionFor('DELETE', '/action-plans/$uuid/items/$item/attachments/$uuid'),
        'action_evidence_deleted');
    expect(Telemetry.actionFor('PATCH', '/action-plans/$uuid/items/$item/review'), 'action_item_reviewed');
    expect(Telemetry.actionFor('post', '/action-plans/$uuid/close'), 'action_plan_closed');
    expect(Telemetry.actionFor('POST', '/audit-questions'), 'audit_question_created');
    expect(Telemetry.actionFor('PATCH', '/audit-questions/reorder'), 'audit_questions_reordered');
    expect(Telemetry.actionFor('PATCH', '/audit-questions/$uuid'), 'audit_question_updated');
    expect(Telemetry.actionFor('DELETE', '/audit-questions/$uuid'), 'audit_question_deactivated');
    expect(Telemetry.actionFor('POST', '/projects'), 'project_created');
    expect(Telemetry.actionFor('PATCH', '/projects/$uuid'), 'project_updated');
    expect(Telemetry.actionFor('DELETE', '/projects/$uuid'), 'project_deleted');
    expect(Telemetry.actionFor('POST', '/users'), 'user_created');
    expect(Telemetry.actionFor('PATCH', '/users/$uuid'), 'user_updated');
    expect(Telemetry.actionFor('DELETE', '/users/$uuid'), 'user_deleted');
    expect(Telemetry.actionFor('POST', '/auth/forgot-password'), 'password_reset_requested');
    expect(Telemetry.actionFor('PATCH', '/notifications/$uuid/read'), 'notification_read');
  });

  test('reads, sign-in, autosave, refresh and unknown paths are not reported', () {
    expect(Telemetry.actionFor('GET', '/audit-plans'), isNull);
    expect(Telemetry.actionFor('GET', '/audit-sheets/$uuid'), isNull);
    expect(Telemetry.actionFor('GET', '/reports/$uuid/pdf'), isNull);
    expect(Telemetry.actionFor('GET', '/reports/export.csv'), isNull);
    // The audit sheet's draft autosave (every 10 s while answering).
    expect(Telemetry.actionFor('PATCH', '/audit-sheets/$uuid'), isNull);
    expect(Telemetry.actionFor('POST', '/auth/login'), isNull);
    expect(Telemetry.actionFor('POST', '/auth/logout'), isNull);
    expect(Telemetry.actionFor('POST', '/auth/refresh'), isNull);
    expect(Telemetry.actionFor('PATCH', '/auth/fcm-token'), isNull);
    expect(Telemetry.actionFor('POST', '/audit-plans/$uuid'), isNull);
    expect(Telemetry.actionFor('POST', '/something-new'), isNull);
  });

  test('off without ET_APP_ID and ET_WRITE_KEY (the default build); calls are safe', () async {
    expect(Telemetry.enabled, isFalse);
    await Telemetry.init();
    Telemetry.screen('/auditor/dashboard');
    Telemetry.track('audit_submitted');
    Telemetry.error('api_error', {'endpoint': '/audit-plans', 'method': 'POST'});
    Telemetry.upload('/audit-sheets/$uuid/upload-image', 201);
    Telemetry.upload('/audit-sheets/$uuid/upload-image', null);
    Telemetry.signedIn(userId: 'u1', role: 'auditor');
    Telemetry.signedOut();
  });

  test('the interceptor changes nothing about a request or its outcome', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.invalid'))
      ..httpClientAdapter = _Answer()
      ..interceptors.add(TelemetryInterceptor());
    final ok = await dio.post<dynamic>('/audit-plans', data: {'x': 1});
    expect(ok.statusCode, 201);
    expect((ok.data as Map)['success'], isTrue);
    await expectLater(
      dio.post<dynamic>('/audit-sheets/$uuid/submit'),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 503)),
    );
  });
}

/// Answers 201 for a new audit plan and 503 for anything else, with no
/// network.
class _Answer implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final created = options.path == '/audit-plans';
    return ResponseBody.fromString(
      jsonEncode({'success': created}),
      created ? 201 : 503,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
