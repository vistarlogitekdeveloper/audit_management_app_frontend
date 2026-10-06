# audit_management_app_frontend

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)

- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Usage analytics (event tracker)

`lib/core/telemetry/telemetry.dart`, using the in-house `vistar_event_tracker`
SDK (vendored in `packages/`, see its `VENDORED.md`). Read in the Platform
Console under Analytics > Event tracker.

**Off unless the build gets both `ET_APP_ID` and `ET_WRITE_KEY`**; without them
nothing is initialised and the app behaves exactly as before. To switch it on:

1. Register `audit_app` in the Platform Console, Settings > Event tracker, and
   copy its write key.
2. Web (Cloudflare Workers Builds `audit-management-app-frontend`, built from
   source on every push to `main`): add the build variables
   `ET_APP_ID=audit_app` and `ET_WRITE_KEY` (Settings > Build > Variables and
   secrets; paste the values with no leading space or newline), then redeploy.
   `build.sh` and `npm run build` both pass the two defines when both are set.
   If the dashboard's build command is an inline `flutter build web ...`
   instead, append
   ` --dart-define=ET_APP_ID=$ET_APP_ID --dart-define=ET_WRITE_KEY=$ET_WRITE_KEY`
   to it.
3. APK: `flutter build apk --release --dart-define=ET_APP_ID=audit_app --dart-define=ET_WRITE_KEY=wk_...`

The `build/web` folder committed in this repository is a stale bundle (June
2026) and is not what is served; nothing there needs rebuilding.

Events go to the host of `ApiConstants.baseUrl`; `ET_BASE_URL` overrides it.

Sent: screen views by route pattern (ids replaced), sign-in / sign-out (the
user as `audit:<id>` with their role), named actions from successful writes
(`audit_plan_created`, `audit_submitted`, `audit_acknowledged`,
`action_item_reviewed`, `action_plan_closed`, ... see `_actions`), failed API
calls (5xx / no connection) and client errors by type. Never sent: request or
response bodies, audit findings, observations, results, scores, remarks,
photos, evidence, auditee / project / user names, emails or phone numbers.
Nothing is awaited by a screen, an audit, a sign-in or a sign-out; start-up
waits at most 2 s; the event queue is capped at 200.
