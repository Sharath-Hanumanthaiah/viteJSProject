#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
EXISTING_USERNAME="takenname-${CASE_SUFFIX}"
EXISTING_EMAIL="taken-${CASE_SUFFIX}@test.com"
NEW_EMAIL="different-${CASE_SUFFIX}@test.com"
TMP_DIR="$(mktemp -d)"
FIRST_RESPONSE="$TMP_DIR/first_response.json"
FIRST_STATUS="$TMP_DIR/first_status.txt"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/status.txt"
trap 'rm -rf "$TMP_DIR"' EXIT

# Given
cat >"$TMP_DIR/existing_user.json" <<EOF
{
  "username": "$EXISTING_USERNAME",
  "email": "$EXISTING_EMAIL",
  "password": "pass456",
  "fullName": "Taken User ${CASE_SUFFIX}"
}
EOF
curl -sS -o "$FIRST_RESPONSE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data @"$TMP_DIR/existing_user.json" > "$FIRST_STATUS"
[ "$(cat "$FIRST_STATUS")" = "201" ]

cat >"$TMP_DIR/request.json" <<EOF
{
  "username": "$EXISTING_USERNAME",
  "email": "$NEW_EMAIL",
  "password": "pass456",
  "fullName": "New Person ${CASE_SUFFIX}"
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
assert data.get('message') == 'Username or Email already registered.', 'unexpected error message'
PY

# Cleanup
# No cleanup available: setup used public signup only and the service exposes no delete/reset API.

echo "CODEVALID_TEST_ASSERTION_OK:signup_duplicate_username"
