#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EXISTING_EMAIL="test-${CASE_SUFFIX}@test.com"
SETUP_FILE="/tmp/signup_email_case_insensitive_duplicate_setup_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/signup_email_case_insensitive_duplicate_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$SETUP_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — create a user, then derive the same email in upper case.
SETUP_STATUS="$(curl -sS -o "$SETUP_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"testuser-${CASE_SUFFIX}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"pass123\",\"fullName\":\"Existing User\"}")"
[ "$SETUP_STATUS" = "201" ]
UPPER_EMAIL="$(printf '%s' "$EXISTING_EMAIL" | tr '[:lower:]' '[:upper:]')"

# When — send signup request using the same email with different case.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"newperson-${CASE_SUFFIX}\",\"email\":\"${UPPER_EMAIL}\",\"password\":\"pass789\",\"fullName\":\"New Person\"}")"

# Then — verify 400 response and duplicate-registration message.
[ "$HTTP_STATUS" = "400" ]
grep -F '"message":"Username or Email already registered."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_email_case_insensitive_duplicate"

# Cleanup — no API or DB cleanup path exists for in-memory users; temp files removed by trap.
