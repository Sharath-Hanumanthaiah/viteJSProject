#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
USERNAME="jane-${CASE_SUFFIX}"
EMAIL="jane.${CASE_SUFFIX}@example.com"
CORRECT_PASSWORD="CorrectPass456"
WRONG_PASSWORD="WrongPassword789"
FULL_NAME="Jane Smith ${CASE_SUFFIX}"
TMP_DIR="$(mktemp -d)"
STATUS_FILE="$TMP_DIR/response.status"
RESPONSE_FILE="$TMP_DIR/response.json"
cleanup_files() { rm -rf "$TMP_DIR"; }
trap cleanup_files EXIT

# Given — create a real user with a known correct password
cat >"$TMP_DIR/signup.json" <<EOF
{"username":"${USERNAME}","email":"${EMAIL}","password":"${CORRECT_PASSWORD}","fullName":"${FULL_NAME}"}
EOF
curl -sS -o "$TMP_DIR/signup-response.json" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data @"$TMP_DIR/signup.json" > "$TMP_DIR/signup.status"
[ "$(cat "$TMP_DIR/signup.status")" = "201" ]

# When — attempt signin with the wrong password
cat >"$TMP_DIR/signin.json" <<EOF
{"email":"${EMAIL}","password":"${WRONG_PASSWORD}"}
EOF
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data @"$TMP_DIR/signin.json" > "$STATUS_FILE"

# Then — verify invalid credentials response
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "401" ]
python3 - "$RESPONSE_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert data.get('message') == 'Invalid email or password.'
PY

echo "CODEVALID_TEST_ASSERTION_OK:signin_wrong_password_returns_401"

# Cleanup — no persistent cleanup available; in-memory app state is isolated to the test container lifecycle
