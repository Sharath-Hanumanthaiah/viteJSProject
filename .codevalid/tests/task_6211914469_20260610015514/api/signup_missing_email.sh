#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USERNAME="noemail-${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/signup_missing_email_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — prepare a unique username while omitting email.
: > /dev/null

# When — send signup request without email.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"password\":\"pass123\",\"fullName\":\"Test User\"}")"

# Then — verify 400 response and required-fields message.
[ "$HTTP_STATUS" = "400" ]
grep -F '"message":"Username, email, password, and full name are required."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_missing_email"

# Cleanup — temp file removed by trap.
