#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
TMP_DIR="$(mktemp -d)"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/status.txt"
trap 'rm -rf "$TMP_DIR"' EXIT

# Given — stateless request body with missing password
REQUEST_BODY='{"email":"test.user@example.com"}'

# When — attempt signin without password
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data "$REQUEST_BODY" > "$STATUS_FILE"

# Then — verify validation error
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
python3 - "$RESPONSE_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert data == {"message": "Email and password are required."}, data
PY

# Cleanup — no side effects to undo

echo "CODEVALID_TEST_ASSERTION_OK:signin_missing_password_returns_400"
