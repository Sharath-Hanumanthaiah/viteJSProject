#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EXISTING_USERNAME="testuser-${CASE_SUFFIX}"
EXISTING_EMAIL_LOWER="caseemail-${CASE_SUFFIX}@test.com"
DUPLICATE_EMAIL_UPPER="CASEEMAIL-${CASE_SUFFIX}@TEST.COM"
NEW_USERNAME="newperson-${CASE_SUFFIX}"
SETUP_RESPONSE_FILE="/tmp/signup_email_case_insensitive_duplicate_setup_${CASE_SUFFIX}.json"
SETUP_STATUS_FILE="/tmp/signup_email_case_insensitive_duplicate_setup_${CASE_SUFFIX}.status"
RESPONSE_FILE="/tmp/signup_email_case_insensitive_duplicate_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/signup_email_case_insensitive_duplicate_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$SETUP_RESPONSE_FILE" "$SETUP_STATUS_FILE" "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given — create an existing user with a lowercase email
curl -sS -o "$SETUP_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME}\",\"email\":\"${EXISTING_EMAIL_LOWER}\",\"password\":\"SeedPass123!\",\"fullName\":\"Existing Case Email ${CASE_SUFFIX}\"}" \
  > "$SETUP_STATUS_FILE"
[ "$(cat "$SETUP_STATUS_FILE")" = "201" ]

# When — submit signup request with same email in different case
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${NEW_USERNAME}\",\"email\":\"${DUPLICATE_EMAIL_UPPER}\",\"password\":\"pass789\",\"fullName\":\"New Person ${CASE_SUFFIX}\"}" \
  > "$STATUS_FILE"

# Then — expect case-insensitive duplicate detection
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
grep -F '"message":"Username or Email already registered."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_email_case_insensitive_duplicate"

# Cleanup — no delete endpoint exists for users in this in-memory API; test data is isolated and reset with container lifecycle
