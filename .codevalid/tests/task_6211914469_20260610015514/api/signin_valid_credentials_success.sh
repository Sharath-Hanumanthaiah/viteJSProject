#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
USERNAME="john-${CASE_SUFFIX}"
EMAIL="john.${CASE_SUFFIX}@example.com"
PASSWORD="SecurePass123!"
FULL_NAME="John Doe ${CASE_SUFFIX}"
TMP_DIR="$(mktemp -d)"
SIGNUP_BODY="$TMP_DIR/signup.json"
SIGNUP_STATUS="$TMP_DIR/signup.status"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/response.status"
cleanup_files() { rm -rf "$TMP_DIR"; }
trap cleanup_files EXIT

# Given — create a unique user that can successfully sign in
cat >"$SIGNUP_BODY" <<EOF
{"username":"${USERNAME}","email":"${EMAIL}","password":"${PASSWORD}","fullName":"${FULL_NAME}"}
EOF
curl -sS -o "$TMP_DIR/signup-response.json" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data @"$SIGNUP_BODY" > "$SIGNUP_STATUS"
[ "$(cat "$SIGNUP_STATUS")" = "201" ]

# When — sign in with the created credentials
cat >"$TMP_DIR/signin.json" <<EOF
{"email":"${EMAIL}","password":"${PASSWORD}"}
EOF
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data @"$TMP_DIR/signin.json" > "$STATUS_FILE"

# Then — verify successful authentication payload and no password exposure
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
python3 - "$RESPONSE_FILE" "$EMAIL" <<'PY'
import json, sys
path, expected_email = sys.argv[1], sys.argv[2]
with open(path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert isinstance(data, dict)
assert 'user' in data and isinstance(data['user'], dict)
user = data['user']
assert user.get('email') == expected_email
assert user.get('id')
assert 'password' not in user
assert isinstance(data.get('token'), str)
assert data['token'].startswith('simulated-jwt-token-for-')
PY
! grep -F 'SecurePass123!' "$RESPONSE_FILE" >/dev/null 2>&1

echo "CODEVALID_TEST_ASSERTION_OK:signin_valid_credentials_success"

# Cleanup — no persistent cleanup available; in-memory app state is isolated to the test container lifecycle
