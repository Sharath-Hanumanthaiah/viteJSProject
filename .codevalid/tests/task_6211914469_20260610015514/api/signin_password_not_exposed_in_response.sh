#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
USERNAME="secure-${CASE_SUFFIX}"
EMAIL="secure.user.${CASE_SUFFIX}@test.com"
PASSWORD="HiddenPass111"
FULL_NAME="Secure User ${CASE_SUFFIX}"
TMP_DIR="$(mktemp -d)"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/response.status"
cleanup_files() { rm -rf "$TMP_DIR"; }
trap cleanup_files EXIT

# Given — create a user whose password must never be returned by signin
cat >"$TMP_DIR/signup.json" <<EOF
{"username":"${USERNAME}","email":"${EMAIL}","password":"${PASSWORD}","fullName":"${FULL_NAME}"}
EOF
curl -sS -o "$TMP_DIR/signup-response.json" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data @"$TMP_DIR/signup.json" > "$TMP_DIR/signup.status"
[ "$(cat "$TMP_DIR/signup.status")" = "201" ]

# When — sign in with the created credentials
cat >"$TMP_DIR/signin.json" <<EOF
{"email":"${EMAIL}","password":"${PASSWORD}"}
EOF
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data @"$TMP_DIR/signin.json" > "$STATUS_FILE"

# Then — verify the password is stripped from the response
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
python3 - "$RESPONSE_FILE" "$EMAIL" <<'PY'
import json, sys
path, expected_email = sys.argv[1], sys.argv[2]
with open(path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
user = data.get('user')
assert isinstance(user, dict)
assert user.get('email') == expected_email
assert user.get('id')
assert 'password' not in user
assert 'token' in data and isinstance(data['token'], str)
PY
! grep -F 'HiddenPass111' "$RESPONSE_FILE" >/dev/null 2>&1
! grep -F '"password"' "$RESPONSE_FILE" >/dev/null 2>&1

echo "CODEVALID_TEST_ASSERTION_OK:signin_password_not_exposed_in_response"

# Cleanup — no persistent cleanup available; in-memory app state is isolated to the test container lifecycle
