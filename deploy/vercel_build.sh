#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR="/tmp/flutter"
FLUTTER_REPO="https://github.com/flutter/flutter.git"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
API_BASE_URL="${PUBLIC_API_URL:-}"

if [ -z "$API_BASE_URL" ] && [ -n "${VERCEL_URL:-}" ]; then
  API_BASE_URL="https://${VERCEL_URL}"
fi

if [ -z "$API_BASE_URL" ]; then
  echo "PUBLIC_API_URL is not set and VERCEL_URL is unavailable."
  echo "Please configure PUBLIC_API_URL in Vercel environment variables."
  exit 1
fi

if [ ! -d "$FLUTTER_DIR/.git" ]; then
  git clone "$FLUTTER_REPO" -b "$FLUTTER_CHANNEL" --depth 1 "$FLUTTER_DIR"
fi

export PATH="$PATH:$FLUTTER_DIR/bin"

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release --dart-define=GUOXUE_API_BASE_URL="$API_BASE_URL"
