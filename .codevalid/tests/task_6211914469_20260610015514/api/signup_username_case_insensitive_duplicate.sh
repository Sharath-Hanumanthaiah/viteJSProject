#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EXISTING_USERNAME="johnsmith-${CASE_SUFFIX}"
SETUP_FILE="/tmp/signup_username_case_insensitive_duplicate_setup_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/signup_username_case_insensitive_duplicate_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$SETUP_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — create a user, then derive the same username in upper case.
SETUP_STATUS="$(curl -sS -o "$SETUP_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME}\",\"email\":\"john-${CASE_SUFFIX}@test.com\",\"password\":\"pass123\",\"fullName\":\"John Smith\"}")"
[ "$SETUP_STATUS" = "201" ]
UPPER_USERNAME="$(printf '%s' "$EXISTING_USERNAME" | tr '[:lower:]' '[:upper:]')"

# When — send signup request using the same username with different case.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${UPPER_USERNAME}\",\"email\":\"different-${CASE_SUFFIX}@email.com\",\"password\":\"pass111\",\"fullName\":\"John Smith 2\"}")"

# Then — verify 400 response and duplicate-registration message.
[ "$HTTP_STATUS" = "400" ]
grep -F '"message":"Username or Email already registered."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_username_case_insensitive_duplicate"

# Cleanup — no API or DB cleanup path exists for in-memory users; temp files removed by trap.
