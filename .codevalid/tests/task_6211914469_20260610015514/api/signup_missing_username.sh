#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EMAIL="nousername-${CASE_SUFFIX}@test.com"
RESPONSE_FILE="/tmp/signup_missing_username_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — prepare a unique email while omitting username.
: > /dev/null

# When — send signup request without username.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"${EMAIL}\",\"password\":\"pass123\",\"fullName\":\"Test User\"}")"

# Then — verify 400 response and required-fields message.
[ "$HTTP_STATUS" = "400" ]
grep -F '"message":"Username, email, password, and full name are required."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_missing_username"

# Cleanup — temp file removed by trap.
