import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show FlutterError;
import 'package:vistar_event_tracker/vistar_event_tracker.dart'
    show EventType, TrackerConfig, VistarEventTracker, VistarEvents;

import '../constants/api_constants.dart';

/// Usage analytics for the Audit app, sent to the in-house event tracker and
/// read in the Platform Console under Analytics > Event tracker.
///
/// Off unless the build is given both:
///   --dart-define=ET_APP_ID=audit_app --dart-define=ET_WRITE_KEY=wk_...
/// (register the app in the Platform Console, Settings > Event tracker; the
/// write key only lets a client append events, so it may ship in the app).
/// Optional --dart-define=ET_BASE_URL=... sends a test build's events
/// somewhere other than the API host the app uses (by default, the host of
/// ApiConstants.baseUrl).
///
/// What is sent:
///   * screen views, by route pattern (ids replaced: `/auditor/audit/:id`)
///   * sign-in / sign-out; the user as `audit:<user id>`, with their role as
///     the only trait (the login response carries no organisation code)
///   * named actions from successful API writes (see [_actions]):
///     `audit_plan_created`, `audit_submitted`, `audit_acknowledged`,
///     `action_item_reviewed`, `action_plan_closed`, ...
///   * failed API calls (5xx or no connection), and client errors by TYPE
///     only (never the message, which can quote a server reply)
/// Never sent: request or response bodies, audit findings, observations,
/// pass / fail results, scores, remarks, photos, evidence files, auditee,
/// project or user names, emails, phone numbers or any other record content.
///
/// NEVER IN THE WAY OF WORK. Nothing here is awaited by a screen, an audit, a
/// sign-in or a sign-out; start-up waits at most [_initBudget]; every call
/// swallows its own failures; the queue is capped at [_maxQueue] events
/// (oldest dropped) and lives in shared preferences; sending is in the
/// background with the SDK's backoff.
abstract final class Telemetry {
  static const _appId = String.fromEnvironment('ET_APP_ID');
  static const _writeKey = String.fromEnvironment('ET_WRITE_KEY');
  static const _baseUrlOverride = String.fromEnvironment('ET_BASE_URL');
  static const _appVersion = String.fromEnvironment('APP_VERSION');
  static const _initBudget = Duration(seconds: 2);
  static const _maxQueue = 200;

  static bool get enabled => _appId != '' && _writeKey != '';

  static VistarEventTracker get _t => VistarEventTracker.instance;
  static bool get _on => enabled && _t.isInitialized;

  static String? _lastScreen;
  static Future<void>? _resetting;

  static String get _origin {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    final u = Uri.parse(ApiConstants.baseUrl);
    return '${u.scheme}://${u.authority}';
  }

  static Future<void> init() async {
    if (!enabled) return;
    try {
      await _t
          .init(TrackerConfig(
            appId: _appId,
            writeKey: _writeKey,
            baseUrl: _origin,
            appVersion: _appVersion.isEmpty ? null : _appVersion,
            maxQueueSize: _maxQueue,
            // The SDK's own error capture sends the exception message and
            // stack, and a message here can quote a server reply (a remark,
            // a project name). [_captureErrors] sends the type only.
            autoCaptureErrors: false,
          ))
          .timeout(_initBudget);
      _captureErrors();
    } catch (_) {
      // Analytics must never stop the app from starting.
    }
  }

  /// Client errors, by type only. Chains to whatever handled them before, so
  /// the app's own error handling is unchanged.
  static void _captureErrors() {
    if (!_on) return;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      _clientError(details.exception, fatal: false, library: details.library);
      previous?.call(details);
    };
    final dispatcher = PlatformDispatcher.instance;
    final previousAsync = dispatcher.onError;
    dispatcher.onError = (error, stack) {
      _clientError(error, fatal: true);
      return previousAsync?.call(error, stack) ?? false;
    };
  }

  static void _clientError(Object e, {required bool fatal, String? library}) {
    try {
      error(VistarEvents.clientError, {
        'error': e.runtimeType.toString(),
        if (library != null) 'library': library,
        'fatal': fatal,
      });
    } catch (_) {}
  }

  /// A screen, by its route pattern. Repeats are dropped.
  static void screen(String location) {
    if (!_on) return;
    final name = routePattern(location);
    if (name == _lastScreen) return;
    _lastScreen = name;
    _guard(() => _t.screen(name));
  }

  static void track(String name, [Map<String, dynamic>? properties]) {
    if (_on) _guard(() => _t.track(name, properties: properties));
  }

  static void error(String name, Map<String, dynamic> properties) {
    if (_on) {
      _guard(() => _t.track(name, properties: properties, type: EventType.error));
    }
  }

  static void _guard(void Function() fn) {
    try {
      fn();
    } catch (_) {
      // Analytics never surfaces as an app error.
    }
  }

  /// Fire and forget: the sign-in never waits for analytics.
  ///
  /// Called just BEFORE the auth state changes. With no sign-out in flight the
  /// SDK sets the user synchronously (before its first await), so the screen
  /// the sign-in leads to is already attributed to them.
  static void signedIn({required String userId, String? role}) {
    if (!_on || userId.isEmpty) return;
    final id = 'audit:$userId';
    final traits = <String, dynamic>{
      if (role != null && role.isNotEmpty) 'role': role,
    };
    final pending = _resetting;
    if (pending == null) {
      _identify(id, traits);
      return;
    }
    // A sign-out just before (a shared device changing hands) resets the
    // identity; let it finish so this one is not wiped by it.
    unawaited(() async {
      try {
        await pending.timeout(const Duration(seconds: 5), onTimeout: () {});
      } catch (_) {}
      _identify(id, traits);
    }());
  }

  static void _identify(String id, Map<String, dynamic> traits) {
    try {
      unawaited(_t.identify(id, traits: traits).catchError((Object _) {}));
    } catch (_) {}
  }

  /// Fire and forget: the sign-out never waits for analytics (the SDK's reset
  /// sends what is queued first, which can take a while on a poor network).
  static void signedOut() {
    _lastScreen = null;
    if (!_on) return;
    try {
      late final Future<void> done;
      done = _t.reset().catchError((Object _) {}).whenComplete(() {
        if (identical(_resetting, done)) _resetting = null;
      });
      _resetting = done;
    } catch (_) {}
  }

  /// `/auditor/audit/9f3c...-...?x=1` -> `/auditor/audit/:id`.
  ///
  /// Any segment with a digit in it is replaced: numbers and uuids become
  /// `:id`; everything else with a digit (a project or site code, a
  /// reference number) becomes `:ref`. The query string is dropped. An API
  /// version segment (`v1`) is kept.
  static String routePattern(String location) {
    final path = Uri.tryParse(location)?.path ?? location.split('?').first;
    return path.split('/').map((s) {
      if (s.isEmpty) return s;
      if (RegExp(r'^\d+$').hasMatch(s)) return ':id';
      if (RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-', caseSensitive: false).hasMatch(s)) return ':id';
      if (RegExp(r'^v\d{1,2}$').hasMatch(s)) return s;
      if (RegExp(r'\d').hasMatch(s)) return ':ref';
      return s;
    }).join('/');
  }

  static const _x = r':(id|ref)';

  /// Successful API writes worth naming, by method and path (ids stripped).
  /// First match wins; anything else (reads, sign-in / sign-out, token
  /// refresh, the audit sheet's draft autosave, unknown paths) is not
  /// reported. Paths are relative to ApiConstants.baseUrl (`.../api/v1/audit`).
  static final List<(String, RegExp, String)> _actions = [
    // Audit plans (admin)
    ('POST', RegExp(r'^/audit-plans$'), 'audit_plan_created'),
    ('PATCH', RegExp(r'^/audit-plans/release$'), 'audit_plan_released'),
    ('PATCH', RegExp('^/audit-plans/$_x/release\$'), 'audit_plan_released'),
    ('PATCH', RegExp('^/audit-plans/$_x/reschedule\$'), 'audit_rescheduled'),
    ('PATCH', RegExp('^/audit-plans/$_x\$'), 'audit_plan_updated'),
    ('DELETE', RegExp('^/audit-plans/$_x/hard-delete\$'), 'audit_plan_deleted'),
    ('DELETE', RegExp('^/audit-plans/$_x\$'), 'audit_plan_cancelled'),
    // Audit sheets (auditor, then project owner / cluster manager)
    ('POST', RegExp('^/audit-sheets/$_x/upload-image\$'), 'audit_photo_uploaded'),
    ('POST', RegExp('^/audit-sheets/$_x/submit\$'), 'audit_submitted'),
    ('POST', RegExp('^/audit-sheets/$_x/acknowledge\$'), 'audit_acknowledged'),
    // Action plans (project owner, then auditor)
    ('PATCH', RegExp('^/action-plans/$_x\$'), 'action_plan_updated'),
    ('POST', RegExp('^/action-plans/$_x/items/$_x/attachments\$'), 'action_evidence_uploaded'),
    ('DELETE', RegExp('^/action-plans/$_x/items/$_x/attachments/$_x\$'), 'action_evidence_deleted'),
    ('PATCH', RegExp('^/action-plans/$_x/items/$_x/review\$'), 'action_item_reviewed'),
    ('POST', RegExp('^/action-plans/$_x/close\$'), 'action_plan_closed'),
    // Masters (admin)
    ('POST', RegExp(r'^/audit-questions$'), 'audit_question_created'),
    ('PATCH', RegExp(r'^/audit-questions/reorder$'), 'audit_questions_reordered'),
    ('PATCH', RegExp('^/audit-questions/$_x\$'), 'audit_question_updated'),
    ('DELETE', RegExp('^/audit-questions/$_x\$'), 'audit_question_deactivated'),
    ('POST', RegExp(r'^/projects$'), 'project_created'),
    ('PATCH', RegExp('^/projects/$_x\$'), 'project_updated'),
    ('DELETE', RegExp('^/projects/$_x\$'), 'project_deleted'),
    ('POST', RegExp(r'^/users$'), 'user_created'),
    // Also the profile screen's own edits and password changes: same endpoint.
    ('PATCH', RegExp('^/users/$_x\$'), 'user_updated'),
    ('DELETE', RegExp('^/users/$_x\$'), 'user_deleted'),
    // Account and notifications
    ('POST', RegExp(r'^/auth/forgot-password$'), 'password_reset_requested'),
    ('PATCH', RegExp('^/notifications/$_x/read\$'), 'notification_read'),
  ];

  /// The business event for a successful API call, or null.
  static String? actionFor(String method, String path) {
    final pattern = routePattern(path);
    final m = method.toUpperCase();
    for (final (am, re, name) in _actions) {
      if (am == m && re.hasMatch(pattern)) return name;
    }
    return null;
  }

  /// The outcome of a photo / evidence upload, which goes through the app's
  /// own multipart sender, not Dio (core/services/multipart_dispatcher.dart).
  /// Same rules as [TelemetryInterceptor]: a 2xx is a named action, a 5xx or
  /// a failed send ([status] null, or 0 from the browser) is an `api_error`,
  /// a 4xx is neither.
  static void upload(String path, int? status) {
    if (!enabled) return;
    try {
      final sent = status != null && status != 0;
      if (sent && status >= 200 && status < 300) {
        final name = actionFor('POST', path);
        if (name != null) track(name);
      } else if (!sent || status >= 500) {
        error('api_error', {
          'endpoint': routePattern(path),
          'method': 'POST',
          if (sent) 'status': status,
          'kind': sent ? 'badResponse' : 'connectionError',
        });
      }
    } catch (_) {}
  }
}

/// Reports named actions and failed calls from the app's Dio client
/// (ApiService.dio). Adds no headers and changes nothing about the request or
/// its handling.
class TelemetryInterceptor extends Interceptor {
  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    // This client uses Dio's default validateStatus, so only a 2xx arrives
    // here; a 2xx whose envelope says `success: false` did not happen either.
    final code = response.statusCode ?? 0;
    if (Telemetry.enabled && code >= 200 && code < 300) {
      String? name;
      try {
        final body = response.data;
        final refused = body is Map && body['success'] == false;
        final o = response.requestOptions;
        if (!refused) name = Telemetry.actionFor(o.method, o.path);
      } catch (_) {}
      if (name != null) Telemetry.track(name);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (Telemetry.enabled) {
      try {
        final status = err.response?.statusCode;
        // A 4xx is a decision the server made (validation, a 401 that ends
        // the session), and a cancel is the app's own.
        if ((status == null || status >= 500) && err.type != DioExceptionType.cancel) {
          Telemetry.error('api_error', {
            'endpoint': Telemetry.routePattern(err.requestOptions.path),
            'method': err.requestOptions.method,
            if (status != null) 'status': status,
            'kind': err.type.name,
          });
        }
      } catch (_) {}
    }
    handler.next(err);
  }
}
