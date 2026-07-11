#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
USERNAME="signin-case-${CASE_SUFFIX}"
ORIGINAL_EMAIL="Admin.${CASE_SUFFIX}@Example.COM"
SIGNIN_EMAIL="admin.${CASE_SUFFIX}@example.com"
PASSWORD="AdminPass999"
FULL_NAME="Admin User ${CASE_SUFFIX}"
TMP_DIR="$(mktemp -d)"
SIGNUP_BODY="$TMP_DIR/signup.json"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/status.txt"
trap 'rm -rf "$TMP_DIR"' EXIT

cat >"$SIGNUP_BODY" <<EOF
{"username":"${USERNAME}","email":"${ORIGINAL_EMAIL}","password":"${PASSWORD}","fullName":"${FULL_NAME}"}
EOF

# Given — create a user whose stored email contains different letter casing
SIGNUP_STATUS="$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data @"$SIGNUP_BODY")"
[ "$SIGNUP_STATUS" = "201" ]

# When — sign in using a differently cased email value
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"${SIGNIN_EMAIL}\",\"password\":\"${PASSWORD}\"}" > "$STATUS_FILE"

# Then — verify signin succeeds and returns the matching user
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
python3 - "$RESPONSE_FILE" "$ORIGINAL_EMAIL" "$FULL_NAME" <<'PY'
import json, sys
path, original_email, full_name = sys.argv[1:4]
with open(path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert data['token'].startswith('simulated-jwt-token-for-')
user = data['user']
assert user['email'] == original_email, user
assert user['fullName'] == full_name, user
assert 'password' not in user, user
PY

# Cleanup — no persistent cleanup needed for in-memory app-only service

echo "CODEVALID_TEST_ASSERTION_OK:signin_case_insensitive_email_success"
