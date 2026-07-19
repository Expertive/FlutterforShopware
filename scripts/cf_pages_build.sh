#!/usr/bin/env bash
# Cloudflare Pages build entrypoint.
# Dashboard:
#   Build command:        bash scripts/cf_pages_build.sh
#   Build output dir:     build/web
#   Root directory:       /
#
# Set these Environment variables (Production + Preview) in Cloudflare:
#   SHOPWARE_BASE_URL
#   SHOPWARE_SALES_CHANNEL_ID
#   MOBILE_APP_SECRET

set -euo pipefail

: "${SHOPWARE_BASE_URL:?Set SHOPWARE_BASE_URL in Cloudflare env vars}"
: "${SHOPWARE_SALES_CHANNEL_ID:?Set SHOPWARE_SALES_CHANNEL_ID in Cloudflare env vars}"
: "${MOBILE_APP_SECRET:?Set MOBILE_APP_SECRET in Cloudflare env vars}"

FLUTTER_DIR="${HOME}/flutter"
if [[ ! -x "${FLUTTER_DIR}/bin/flutter" ]]; then
  echo "Installing Flutter SDK (stable)..."
  git clone https://github.com/flutter/flutter.git \
    --depth 1 \
    -b stable \
    "${FLUTTER_DIR}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"
flutter config --no-analytics
flutter config --enable-web
flutter --version

flutter pub get
flutter build web --release --base-href=/ \
  --dart-define=SHOPWARE_BASE_URL="${SHOPWARE_BASE_URL}" \
  --dart-define=SHOPWARE_SALES_CHANNEL_ID="${SHOPWARE_SALES_CHANNEL_ID}" \
  --dart-define=MOBILE_APP_SECRET="${MOBILE_APP_SECRET}"

echo "flutter.expertive.de" > build/web/CNAME

printf '%s\n' \
  '/*' \
  '  X-Content-Type-Options: nosniff' \
  '/index.html' \
  '  Cache-Control: no-cache, no-store, must-revalidate' \
  '/flutter_bootstrap.js' \
  '  Cache-Control: no-cache, no-store, must-revalidate' \
  '/flutter.js' \
  '  Cache-Control: no-cache, no-store, must-revalidate' \
  '/main.dart.js' \
  '  Cache-Control: public, max-age=3600, must-revalidate' \
  '/version.json' \
  '  Cache-Control: no-cache, no-store, must-revalidate' \
  > build/web/_headers

echo "Cloudflare Pages build done → build/web"
