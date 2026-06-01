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

# 3. Produce the static bundle. `--base-href /` so go_router's deep links
#    resolve correctly when served at the domain root.
flutter build web --release --base-href /

echo "✓ build/web/ ready for deploy"
