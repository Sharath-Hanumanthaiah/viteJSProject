#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EXISTING_USERNAME="takenname-${CASE_SUFFIX}"
EXISTING_EMAIL="taken-${CASE_SUFFIX}@test.com"
SETUP_FILE="/tmp/signup_duplicate_username_setup_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/signup_duplicate_username_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$SETUP_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — create a user whose username will be reused by the request under test.
SETUP_STATUS="$(curl -sS -o "$SETUP_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"pass123\",\"fullName\":\"Taken User\"}")"
[ "$SETUP_STATUS" = "201" ]

# When — send signup request with a duplicate username and different email.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME}\",\"email\":\"different-${CASE_SUFFIX}@test.com\",\"password\":\"pass456\",\"fullName\":\"New Person\"}")"

# Then — verify 400 response and duplicate-registration message.
[ "$HTTP_STATUS" = "400" ]
grep -F '"message":"Username or Email already registered."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_duplicate_username"

# Cleanup — no API or DB cleanup path exists for in-memory users; temp files removed by trap.
