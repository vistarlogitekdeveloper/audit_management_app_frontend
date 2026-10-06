#!/usr/bin/env bash
# Cloudflare Pages build script for this Flutter web app.
#
# Set the Cloudflare project's "Build command" to:   bash build.sh
# Set "Build output directory" to:                   build/web
# Leave "Root directory" empty.
#
# Keeping the actual steps here (rather than only in the dashboard) means
# they're version-controlled, can't get silently wiped from the project
# settings, and review-able in PRs. The corresponding render.yaml has the
# same logic for Render deploys.
set -euo pipefail

# 1. Install the Flutter stable SDK into the build host's HOME (guard so a
#    cached build dir doesn't re-clone).
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git \
    --depth 1 --branch stable "$HOME/flutter"
fi

export PATH="$HOME/flutter/bin:$PATH"

# 2. Make web a known build target + fetch packages.
flutter --version
flutter config --enable-web
flutter pub get

# 3. Usage analytics (lib/core/telemetry/telemetry.dart). On only when BOTH
#    build variables are set: ET_APP_ID (audit_app) and ET_WRITE_KEY
#    (encrypted), under Settings -> Build -> Variables and secrets. Either
#    missing: no define is passed and the app sends nothing, exactly as
#    before. ET_BASE_URL is optional (events go to the API host by default).
#    Never echo the key.
DART_DEFINES=()
if [ -n "${ET_APP_ID:-}" ] && [ -n "${ET_WRITE_KEY:-}" ]; then
  DART_DEFINES+=(--dart-define=ET_APP_ID="${ET_APP_ID}" --dart-define=ET_WRITE_KEY="${ET_WRITE_KEY}")
  [ -n "${ET_BASE_URL:-}" ] && DART_DEFINES+=(--dart-define=ET_BASE_URL="${ET_BASE_URL}")
  echo ">> Usage analytics on, as ${ET_APP_ID}"
else
  echo ">> Usage analytics off (ET_APP_ID / ET_WRITE_KEY not set)"
fi

# 4. Produce the static bundle. `--base-href /` so go_router's deep links
#    resolve correctly when served at the domain root.
flutter build web --release --base-href / "${DART_DEFINES[@]+"${DART_DEFINES[@]}"}"

echo "✓ build/web/ ready for deploy"
