#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
TMP_DIR="$(mktemp -d)"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/response.status"
cleanup_files() { rm -rf "$TMP_DIR"; }
trap cleanup_files EXIT

# Given — use an empty JSON request body
printf '{}' > "$TMP_DIR/request.json"

# When — submit signin request with no email and no password
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data @"$TMP_DIR/request.json" > "$STATUS_FILE"

# Then — verify validation error
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
python3 - "$RESPONSE_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert data.get('message') == 'Email and password are required.'
PY

echo "CODEVALID_TEST_ASSERTION_OK:signin_missing_both_fields_returns_400"

# Cleanup — stateless request; no cleanup required
