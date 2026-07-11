#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
USERNAME="signin-hidden-pass-${CASE_SUFFIX}"
EMAIL="secure.user.${CASE_SUFFIX}@test.com"
PASSWORD="HiddenPass111"
FULL_NAME="Secure User ${CASE_SUFFIX}"
TMP_DIR="$(mktemp -d)"
SIGNUP_BODY="$TMP_DIR/signup.json"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/status.txt"
trap 'rm -rf "$TMP_DIR"' EXIT

cat >"$SIGNUP_BODY" <<EOF
{"username":"${USERNAME}","email":"${EMAIL}","password":"${PASSWORD}","fullName":"${FULL_NAME}"}
EOF

# Given — create a user whose credentials will be used for signin
SIGNUP_STATUS="$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data @"$SIGNUP_BODY")"
[ "$SIGNUP_STATUS" = "201" ]

# When — sign in with valid credentials
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}" > "$STATUS_FILE"

# Then — verify password is not exposed anywhere in the response
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
python3 - "$RESPONSE_FILE" "$EMAIL" "$PASSWORD" <<'PY'
import json, sys
path, email, password = sys.argv[1:4]
raw = open(path, 'r', encoding='utf-8').read()
assert password not in raw, 'plaintext password leaked into response body'
data = json.loads(raw)
user = data['user']
assert user['email'] == email, user
assert 'id' in user and user['id'].startswith('user_'), user
assert 'password' not in user, user
assert data['token'].startswith('simulated-jwt-token-for-'), data
PY

# Cleanup — no persistent cleanup needed for in-memory app-only service

echo "CODEVALID_TEST_ASSERTION_OK:signin_password_not_exposed_in_response"
