#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
USERNAME="admin-${CASE_SUFFIX}"
SIGNUP_EMAIL="Admin.${CASE_SUFFIX}@Example.COM"
SIGNIN_EMAIL="admin.${CASE_SUFFIX}@example.com"
PASSWORD="AdminPass999"
FULL_NAME="Admin User ${CASE_SUFFIX}"
TMP_DIR="$(mktemp -d)"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/response.status"
cleanup_files() { rm -rf "$TMP_DIR"; }
trap cleanup_files EXIT

# Given — create a user whose stored email contains mixed casing
cat >"$TMP_DIR/signup.json" <<EOF
{"username":"${USERNAME}","email":"${SIGNUP_EMAIL}","password":"${PASSWORD}","fullName":"${FULL_NAME}"}
EOF
curl -sS -o "$TMP_DIR/signup-response.json" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data @"$TMP_DIR/signup.json" > "$TMP_DIR/signup.status"
[ "$(cat "$TMP_DIR/signup.status")" = "201" ]

# When — sign in using the same email in lowercase
cat >"$TMP_DIR/signin.json" <<EOF
{"email":"${SIGNIN_EMAIL}","password":"${PASSWORD}"}
EOF
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data @"$TMP_DIR/signin.json" > "$STATUS_FILE"

# Then — verify signin succeeds and matches the created user
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
python3 - "$RESPONSE_FILE" "$SIGNUP_EMAIL" <<'PY'
import json, sys
path, stored_email = sys.argv[1], sys.argv[2]
with open(path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert isinstance(data.get('token'), str)
assert data['token'].startswith('simulated-jwt-token-for-')
user = data.get('user')
assert isinstance(user, dict)
assert user.get('email') == stored_email
assert user.get('id')
assert 'password' not in user
PY

echo "CODEVALID_TEST_ASSERTION_OK:signin_case_insensitive_email_success"

# Cleanup — no persistent cleanup available; in-memory app state is isolated to the test container lifecycle
