#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
USERNAME="signin-wrong-pass-${CASE_SUFFIX}"
EMAIL="signin.wrongpass.${CASE_SUFFIX}@example.com"
CORRECT_PASSWORD="CorrectPass456"
WRONG_PASSWORD="WrongPassword789"
FULL_NAME="Jane Smith ${CASE_SUFFIX}"
TMP_DIR="$(mktemp -d)"
SIGNUP_BODY="$TMP_DIR/signup.json"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/status.txt"
trap 'rm -rf "$TMP_DIR"' EXIT

cat >"$SIGNUP_BODY" <<EOF
{"username":"${USERNAME}","email":"${EMAIL}","password":"${CORRECT_PASSWORD}","fullName":"${FULL_NAME}"}
EOF

# Given — create a user with a known correct password
SIGNUP_STATUS="$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data @"$SIGNUP_BODY")"
[ "$SIGNUP_STATUS" = "201" ]

# When — attempt signin with incorrect password
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"${EMAIL}\",\"password\":\"${WRONG_PASSWORD}\"}" > "$STATUS_FILE"

# Then — verify invalid credentials response
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "401" ]
python3 - "$RESPONSE_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert data == {"message": "Invalid email or password."}, data
PY

# Cleanup — no persistent cleanup needed for in-memory app-only service

echo "CODEVALID_TEST_ASSERTION_OK:signin_wrong_password_returns_401"
