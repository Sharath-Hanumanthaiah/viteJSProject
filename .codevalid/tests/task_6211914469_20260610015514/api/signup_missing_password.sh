#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
USERNAME="nopassuser-${CASE_SUFFIX}"
EMAIL="nopass-${CASE_SUFFIX}@test.com"
TMP_DIR="$(mktemp -d)"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/status.txt"
trap 'rm -rf "$TMP_DIR"' EXIT

# Given
cat >"$TMP_DIR/request.json" <<EOF
{
  "username": "$USERNAME",
  "email": "$EMAIL",
  "fullName": "Test User ${CASE_SUFFIX}"
}
EOF

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data @"$TMP_DIR/request.json" > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
python3 - "$RESPONSE_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert data.get('message') == 'Username, email, password, and full name are required.', 'unexpected error message'
PY

# Cleanup
# No cleanup required: request failed validation and created no resource.

echo "CODEVALID_TEST_ASSERTION_OK:signup_missing_password"
