#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
USERNAME="signin-valid-${CASE_SUFFIX}"
EMAIL="signin.valid.${CASE_SUFFIX}@example.com"
PASSWORD="SecurePass123!"
FULL_NAME="John Doe ${CASE_SUFFIX}"
TMP_DIR="$(mktemp -d)"
SIGNUP_BODY="$TMP_DIR/signup.json"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/status.txt"
trap 'rm -rf "$TMP_DIR"' EXIT

cat >"$SIGNUP_BODY" <<EOF
{"username":"${USERNAME}","email":"${EMAIL}","password":"${PASSWORD}","fullName":"${FULL_NAME}"}
EOF

# Given — create a unique user for this test
SIGNUP_STATUS="$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data @"$SIGNUP_BODY")"
[ "$SIGNUP_STATUS" = "201" ]

# When — sign in with valid credentials
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}" > "$STATUS_FILE"

# Then — verify successful auth response
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
python3 - "$RESPONSE_FILE" "$EMAIL" "$FULL_NAME" <<'PY'
import json, sys
path, email, full_name = sys.argv[1:4]
with open(path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert 'token' in data, 'missing token'
assert data['token'].startswith('simulated-jwt-token-for-'), 'token prefix mismatch'
assert 'user' in data and isinstance(data['user'], dict), 'missing user object'
user = data['user']
assert user.get('email') == email, f"unexpected email: {user.get('email')}"
assert user.get('fullName') == full_name, f"unexpected fullName: {user.get('fullName')}"
assert user.get('id', '').startswith('user_'), f"unexpected id: {user.get('id')}"
assert 'password' not in user, 'password must not be present in user object'
PY

# Cleanup — no persistent cleanup needed for in-memory app-only service

echo "CODEVALID_TEST_ASSERTION_OK:signin_valid_credentials_success"
