#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EXISTING_USERNAME="testuser-${CASE_SUFFIX}"
EXISTING_EMAIL="test-${CASE_SUFFIX}@test.com"
UPPERCASE_EMAIL="TEST-${CASE_SUFFIX}@TEST.COM"
RESPONSE_FILE="/tmp/signup_email_case_insensitive_duplicate_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/signup_email_case_insensitive_duplicate_${CASE_SUFFIX}.status"
SETUP_RESPONSE_FILE="/tmp/signup_email_case_insensitive_duplicate_setup_${CASE_SUFFIX}.json"
SETUP_STATUS_FILE="/tmp/signup_email_case_insensitive_duplicate_setup_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE" "$SETUP_RESPONSE_FILE" "$SETUP_STATUS_FILE"
}
trap cleanup_files EXIT

# Given — create an existing user with the lowercase email
curl -sS -o "$SETUP_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"pass789\",\"fullName\":\"Existing Person ${CASE_SUFFIX}\"}" \
  > "$SETUP_STATUS_FILE"
[ "$(cat "$SETUP_STATUS_FILE")" = "201" ]

# When — attempt signup using the same email with different casing
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"newperson-${CASE_SUFFIX}\",\"email\":\"${UPPERCASE_EMAIL}\",\"password\":\"pass789\",\"fullName\":\"New Person ${CASE_SUFFIX}\"}" \
  > "$STATUS_FILE"

# Then — expect 400 duplicate-user error due to case-insensitive email comparison
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
grep -F '"message":"Username or Email already registered."' "$RESPONSE_FILE" >/dev/null

# Cleanup — no delete endpoint exists for users in this in-memory API; unique setup data isolates test state

echo "CODEVALID_TEST_ASSERTION_OK:signup_email_case_insensitive_duplicate"
