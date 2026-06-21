#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EXISTING_USERNAME="existinguser-${CASE_SUFFIX}"
EXISTING_EMAIL="existing-${CASE_SUFFIX}@test.com"
SETUP_FILE="/tmp/signup_duplicate_email_setup_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/signup_duplicate_email_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$SETUP_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — create a user whose email will be reused by the request under test.
SETUP_STATUS="$(curl -sS -o "$SETUP_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"pass123\",\"fullName\":\"Existing User\"}")"
[ "$SETUP_STATUS" = "201" ]

# When — send signup request with a duplicate email and different username.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"newdifferent-${CASE_SUFFIX}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"newpass123\",\"fullName\":\"Another User\"}")"

# Then — verify 400 response and duplicate-registration message.
[ "$HTTP_STATUS" = "400" ]
grep -F '"message":"Username or Email already registered."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_duplicate_email"

# Cleanup — no API or DB cleanup path exists for in-memory users; temp files removed by trap.
