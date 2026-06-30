#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
TMP_DIR="$(mktemp -d)"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/response.status"
cleanup_files() { rm -rf "$TMP_DIR"; }
trap cleanup_files EXIT

# Given — construct a request body missing the password field
cat >"$TMP_DIR/request.json" <<EOF
{"email":"test.user.${CASE_SUFFIX}@example.com"}
EOF

# When — submit signin request without password
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

echo "CODEVALID_TEST_ASSERTION_OK:signin_missing_password_returns_400"

# Cleanup — stateless request; no cleanup required
