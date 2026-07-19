#!/usr/bin/env bash
# Local web release build for flutter.expertive.de
# Usage:
#   ./scripts/build_web.sh
# Then upload build/web/ to the host (FTP/SFTP/rsync). Do not upload a
# partial main.dart.js — verify size is ~3.5MB+ after upload.

set -euo pipefail
cd "$(dirname "$0")/.."

BASE_URL="${SHOPWARE_BASE_URL:-https://ovtkebdtbjkl-storeqa.eu-exttesting-1.shopware.build/}"
CHANNEL_ID="${SHOPWARE_SALES_CHANNEL_ID:-383daa095f4449839949a420f0759a7e}"
APP_SECRET="${MOBILE_APP_SECRET:-}"

if [[ -z "$APP_SECRET" ]]; then
  echo "Set MOBILE_APP_SECRET in the environment, e.g.:"
  echo "  export MOBILE_APP_SECRET='Ul3Yeyty2J4123'"
  exit 1
fi

flutter build web --release --base-href=/ \
  --dart-define=SHOPWARE_BASE_URL="$BASE_URL" \
  --dart-define=SHOPWARE_SALES_CHANNEL_ID="$CHANNEL_ID" \
  --dart-define=MOBILE_APP_SECRET="$APP_SECRET"

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

SIZE=$(wc -c < build/web/main.dart.js | tr -d ' ')
echo "Built build/web (main.dart.js = $SIZE bytes)"
echo "Upload the FULL build/web folder, then purge Cloudflare cache."
